# frozen_string_literal: true

class ExercisesController < ApplicationController
  include CommonBehavior
  include RedirectBehavior
  include Lti
  include SubmissionParameters
  include TimeHelper

  before_action :handle_file_uploads, only: %i[create update]
  before_action :set_execution_environments, only: %i[index create edit new update]
  before_action :set_exercise_and_authorize,
    only: MEMBER_ACTIONS + %i[clone implement working_times intervention statistics reload feedback
                              study_group_dashboard export_external_check export_external_confirm
                              external_user_statistics]
  before_action :collect_set_and_unset_exercise_tags, only: MEMBER_ACTIONS
  before_action :set_external_user_and_authorize, only: [:external_user_statistics]
  before_action :set_file_types, only: %i[create edit new update]
  before_action :set_available_tips, only: %i[implement show new edit]

  skip_before_action :verify_authenticity_token, only: %i[import_task import_uuid_check]
  skip_after_action :verify_authorized, only: %i[import_task import_uuid_check]
  skip_after_action :verify_policy_scoped, only: %i[import_task import_uuid_check], raise: false

  rescue_from Pundit::NotAuthorizedError, with: :not_authorized_for_exercise

  def authorize!
    authorize(@exercise || @exercises)
  end

  private :authorize!

  def max_intervention_count_per_day
    3
  end

  def max_intervention_count_per_exercise
    1
  end

  def batch_update
    update_map = {}
    update_params = params.permit(exercises: %i[id public])
    update_params[:exercises].each_value do |param|
      update_map[param[:id]] = param[:public]
    end

    @exercises = Exercise.where(id: update_map.keys).includes(:execution_environment, :files)
    authorize!

    @exercises.each do |exercise|
      exercise.update(public: update_map[exercise.id.to_s])
    end
    render(json: {exercises: @exercises})
  end

  def clone
    exercise = @exercise.duplicate(public: false, token: nil, user: current_user)
    exercise.send(:generate_token)
    if exercise.save
      redirect_to(exercise_path(exercise), notice: t('shared.object_cloned', model: Exercise.model_name.human))
    else
      flash[:danger] = t('shared.message_failure')
      redirect_to(@exercise)
    end
  end

  def collect_paths(files)
    unique_paths = files.map(&:path).compact_blank.uniq
    subpaths = unique_paths.map do |path|
      Array.new((path.split('/').length + 1)) do |n|
        path.split('/').shift(n).join('/')
      end
    end
    subpaths.flatten.uniq
  end

  private :collect_paths

  def index
    @search = policy_scope(Exercise).ransack(params[:q])
    @exercises = @search.result.includes(:execution_environment, :user, :files, :exercise_tags).order(:title).paginate(page: params[:page], per_page: per_page_param)
    authorize!
  end

  def show
    # Show exercise details for teachers and admins
  end

  def new
    @exercise = Exercise.new
    authorize!
    collect_set_and_unset_exercise_tags
  end

  def feedback
    authorize!
    @feedbacks = @exercise
      .user_exercise_feedbacks
      .includes(:exercise, user: [:programming_groups])
      .paginate(page: params[:page], per_page: per_page_param)
  end

  def export_external_check
    codeharbor_check = ExerciseService::CheckExternal.call(uuid: @exercise.uuid,
      codeharbor_link: current_user.codeharbor_link)
    render json: {
      message: codeharbor_check[:message],
      actions: render_to_string(
        partial: 'export_actions',
        locals: {
          exercise: @exercise,
          uuid_found: codeharbor_check[:uuid_found],
          update_right: codeharbor_check[:update_right],
          error: codeharbor_check[:error],
          exported: false,
        }
      ),
    }, status: :ok
  end

  def export_external_confirm
    authorize!
    @exercise.uuid = SecureRandom.uuid if @exercise.uuid.nil?

    error = ExerciseService::PushExternal.call(
      zip: ProformaService::ExportTask.call(exercise: @exercise),
      codeharbor_link: current_user.codeharbor_link
    )
    if error.nil?
      render json: {
        status: 'success',
        message: t('exercises.export_codeharbor.successfully_exported', id: @exercise.id, title: @exercise.title),
        actions: render_to_string(partial: 'export_actions',
          locals: {exercise: @exercise, exported: true, error:}),
      }
      @exercise.save
    else
      render json: {
        status: 'fail',
        message: t('exercises.export_codeharbor.export_failed', id: @exercise.id, title: @exercise.title, error:),
        actions: render_to_string(partial: 'export_actions',
          locals: {exercise: @exercise, exported: true, error:}),
      }
    end
  end

  def import_uuid_check
    user = user_from_api_key
    return render json: {}, status: :unauthorized if user.nil?

    uuid = params[:uuid]
    exercise = Exercise.find_by(uuid:)

    return render json: {uuid_found: false} if exercise.nil?
    return render json: {uuid_found: true, update_right: false} unless ExercisePolicy.new(user, exercise).update?

    render json: {uuid_found: true, update_right: true}
  end

  def import_task
    tempfile = Tempfile.new('codeharbor_import.zip')
    tempfile.write request.body.read.force_encoding('UTF-8')
    tempfile.rewind

    user = user_from_api_key
    return render json: {}, status: :unauthorized if user.nil?

    ActiveRecord::Base.transaction do
      exercise = ::ProformaService::Import.call(zip: tempfile, user:)
      exercise.save!
      render json: {}, status: :created
    end
  rescue ProformaXML::ExerciseNotOwned
    render json: {}, status: :unauthorized
  rescue ProformaXML::ProformaError
    render json: t('exercises.import_codeharbor.import_errors.invalid'), status: :bad_request
  rescue StandardError => e
    Sentry.capture_exception(e)
    render json: t('exercises.import_codeharbor.import_errors.internal_error'), status: :internal_server_error
  end

  def user_from_api_key
    authorization_header = request.headers['Authorization']
    api_key = authorization_header&.split&.second
    user_by_codeharbor_token(api_key)
  end

  private :user_from_api_key

  def user_by_codeharbor_token(api_key)
    link = CodeharborLink.find_by(api_key:)
    link&.user
  end

  private :user_by_codeharbor_token

  def exercise_params
    @exercise_params ||= if params[:exercise].present?
                           params[:exercise].permit(
                             :description,
                             :execution_environment_id,
                             :file_id,
                             :instructions,
                             :submission_deadline,
                             :late_submission_deadline,
                             :public,
                             :unpublished,
                             :hide_file_tree,
                             :allow_file_creation,
                             :allow_auto_completion,
                             :title,
                             :internal_title,
                             :expected_difficulty,
                             :tips,
                             files_attributes: file_attributes,
                             tag_ids: []
                           ).merge(
                             user: current_user
                           )
                         end
  end

  private :exercise_params

  def exercise_params_with_tags
    myparam = exercise_params.presence || {}
    checked_exercise_tags = @exercise_tags.select {|et| myparam[:tag_ids]&.include? et.tag.id.to_s }
    removed_exercise_tags = @exercise_tags.reject {|et| myparam[:tag_ids]&.include? et.tag.id.to_s }

    checked_exercise_tags.each do |et|
      et.factor = params[:tag_factors][et.tag_id.to_s][:factor]
      et.exercise = @exercise
    end

    myparam[:exercise_tags] = checked_exercise_tags
    myparam.delete :tag_ids
    myparam.delete :tips
    removed_exercise_tags.map(&:destroy)
    myparam
  end
  private :exercise_params_with_tags

  def handle_file_uploads
    if exercise_params
      exercise_params[:files_attributes].try(:each) do |_index, file_attributes|
        if file_attributes[:content].respond_to?(:read)
          if FileType.find_by(id: file_attributes[:file_type_id]).try(:binary?)
            file_attributes[:native_file] = file_attributes[:content]
            file_attributes[:content] = nil
          else
            file_attributes[:content] = file_attributes[:content].read.detect_encoding!.encode.delete("\x00")
          end
        end
      end
    end
  end

  private :handle_file_uploads

  def handle_exercise_tips(tips_params)
    return unless tips_params

    begin
      exercise_tips = JSON.parse(tips_params)
      # Order is important to ensure no foreign key restraints are violated during delete
      previous_exercise_tips = ExerciseTip.where(exercise: @exercise).select(:id).order(rank: :desc).ids
      remaining_exercise_tips = update_exercise_tips exercise_tips, nil, 1
      # Destroy initializes each object and then calls a *single* SQL DELETE
      ExerciseTip.destroy(previous_exercise_tips - remaining_exercise_tips)
    rescue JSON::ParserError => e
      flash[:danger] = "JSON error: #{e.message}"
      redirect_to(edit_exercise_path(@exercise))
    end
  end

  private :handle_exercise_tips

  def update_exercise_tips(exercise_tips, parent_exercise_tip_id, rank)
    result = []
    exercise_tips.each do |exercise_tip|
      exercise_tip.symbolize_keys!
      current_exercise_tip = ExerciseTip.find_or_initialize_by(id: exercise_tip[:id],
        exercise: @exercise,
        tip_id: exercise_tip[:tip_id])
      current_exercise_tip.parent_exercise_tip_id = parent_exercise_tip_id
      current_exercise_tip.rank = rank
      rank += 1
      unless current_exercise_tip.save
        flash[:danger] = current_exercise_tip.errors.full_messages.join('. ')
        redirect_to(edit_exercise_path(@exercise)) and break
      end

      children = update_exercise_tips exercise_tip[:children], current_exercise_tip.id, rank
      rank += children.length

      result << current_exercise_tip.id
      result += children
    end
    result
  end

  private :update_exercise_tips

  def implement # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    if session[:pg_id] && current_contributor.exercise != @exercise
      # we are acting on behalf of a programming group
      if current_user.admin?
        session.delete(:pg_id)
        session.delete(:pair_programming)
        @current_contributor = current_user
      else
        return redirect_back_or_to(
          implement_exercise_path(current_contributor.exercise),
          alert: t('exercises.implement.existing_programming_group', exercise: current_contributor.exercise.title)
        )
      end
    elsif session[:pg_id].blank? && (pg = current_user.programming_groups.find_by(exercise: @exercise)) && pg.submissions.where(study_group_id: current_user.current_study_group_id).any?
      # we are just acting on behalf of a single user who has already worked on this exercise as part of a programming group **in the context of the current study group**
      session[:pg_id] = pg.id
      @current_contributor = pg
    elsif session[:pg_id].blank? && session[:pair_programming] == 'mandatory'
      return redirect_back_or_to(new_exercise_programming_group_path(@exercise))
    elsif session[:pg_id].blank? && session[:pair_programming] == 'optional' && current_user.submissions.where(study_group_id: current_user.current_study_group_id, exercise: @exercise).none?
      Event.find_or_create_by(category: 'pp_work_alone', user: current_user, exercise: @exercise, data: nil, file_id: nil)
      current_user.pair_programming_waiting_users&.find_by(exercise: @exercise)&.update(status: :worked_alone)
    end

    user_solved_exercise = @exercise.solved_by?(current_contributor)
    count_interventions_today = current_contributor.user_exercise_interventions.where(created_at: Time.zone.now.beginning_of_day..).count
    user_got_intervention_in_exercise = current_contributor.user_exercise_interventions.where(exercise: @exercise).size >= max_intervention_count_per_exercise
    (user_got_enough_interventions = count_interventions_today >= max_intervention_count_per_day) || user_got_intervention_in_exercise

    if @embed_options[:disable_interventions]
      @show_rfc_interventions = false
      @show_break_interventions = false
      @show_tips_interventions = false
    else
      show_intervention = (!user_solved_exercise && !user_got_enough_interventions).to_s
      if @tips.present? && Java21Study.show_tips_intervention?(current_user, @exercise)
        @show_tips_interventions = show_intervention
        @show_break_interventions = false
        @show_rfc_interventions = false
      elsif Java21Study.show_break_intervention?(current_user, @exercise)
        @show_tips_interventions = false
        @show_break_interventions = show_intervention
        @show_rfc_interventions = false
      else
        @show_tips_interventions = false
        @show_break_interventions = false
        @show_rfc_interventions = show_intervention
      end
    end

    @embed_options[:disable_score] = true unless @exercise.teacher_defined_assessment?

    @hide_rfc_button = @embed_options[:disable_rfc]

    @submission = current_contributor.submissions.order(created_at: :desc).find_by(exercise: @exercise)
    @files = (@submission ? @submission.collect_files : @exercise.files).select(&:visible).sort_by(&:filepath)
    @paths = collect_paths(@files)
  end

  def set_available_tips
    # Order of elements is important and will be kept
    available_tips = ExerciseTip.where(exercise: @exercise).order(rank: :asc).includes(:tip)

    # Transform result set in a hash and prepare (temporary) children array.
    # The children array will contain the sorted list of nested tips,
    # shown for learners in the output sidebar with cards.
    # Hash - Key: exercise_tip.id, value: exercise_tip Object loaded from database
    nested_tips = available_tips.each_with_object({}) do |exercise_tip, hash|
      exercise_tip.children = []
      hash[exercise_tip.id] = exercise_tip
    end

    available_tips.each do |tip|
      # A tip without a parent cannot be a children
      next if tip.parent_exercise_tip_id.blank?

      # Link tips if they are related
      nested_tips[tip.parent_exercise_tip_id].children << tip
    end

    # Return an array with top-level tips
    @tips = nested_tips.values.select {|tip| tip.parent_exercise_tip_id.nil? }
  end

  private :set_available_tips

  def working_times
    working_time_accumulated = @exercise.accumulated_working_time_for_only(current_contributor)
    working_time_75_percentile = @exercise.get_quantiles([0.75]).first
    render(json: {working_time_75_percentile:,
                   working_time_accumulated:})
  end

  def intervention
    intervention = Intervention.find_by(name: params[:intervention_type])
    if intervention.nil?
      render(json: {success: 'false', error: "undefined intervention #{params[:intervention_type]}"})
    else
      uei = UserExerciseIntervention.new(
        user: current_contributor, exercise: @exercise, intervention:,
        accumulated_worktime_s: @exercise.accumulated_working_time_for_only(current_contributor)
      )
      uei.save
      render(json: {success: 'true'})
    end
  end

  def edit; end

  def create
    @exercise = Exercise.new(exercise_params&.except(:tips))
    authorize!
    collect_set_and_unset_exercise_tags
    tips_params = exercise_params&.dig(:tips)
    return if performed?

    create_and_respond(object: @exercise, params: exercise_params_with_tags) do
      # We first need to create the exercise before handling tips
      handle_exercise_tips tips_params
      # Don't return a specific value from this block, so that the default is used.
      nil
    end
  end

  def not_authorized_for_exercise(_exception)
    return render_not_authorized unless current_user
    return render_not_authorized unless %w[implement working_times intervention reload].include?(action_name)

    if current_user.admin? || current_user.teacher?
      redirect_to(@exercise, alert: t('exercises.implement.unpublished')) if @exercise.unpublished?
      redirect_to(@exercise, alert: t('exercises.implement.no_files')) unless @exercise.files.visible.exists?
      redirect_to(@exercise, alert: t('exercises.implement.no_execution_environment')) if @exercise.execution_environment.blank?
    else
      render_not_authorized
    end
  end
  private :not_authorized_for_exercise

  def set_execution_environments
    @execution_environments = ExecutionEnvironment.order(:name)
  end

  private :set_execution_environments

  def set_exercise_and_authorize
    @exercise = Exercise.includes(:exercise_tips, files: [:file_type]).find(params[:id])
    authorize!
  end

  private :set_exercise_and_authorize

  def set_external_user_and_authorize
    if params[:external_user_id]
      @external_user = ExternalUser.find(params[:external_user_id])
      authorize!
    end
  end

  private :set_external_user_and_authorize

  def set_file_types
    @file_types = FileType.order(:name)
  end

  private :set_file_types

  def collect_set_and_unset_exercise_tags
    @tags = policy_scope(Tag)
    checked_exercise_tags = @exercise.exercise_tags
    checked_tags = checked_exercise_tags.to_set(&:tag)
    unchecked_tags = Tag.all.to_set.subtract checked_tags
    @exercise_tags = checked_exercise_tags + unchecked_tags.collect do |tag|
      ExerciseTag.new(exercise: @exercise, tag:)
    end
  end

  private :collect_set_and_unset_exercise_tags

  def update
    handle_exercise_tips exercise_params&.dig(:tips)
    return if performed?

    update_and_respond(object: @exercise, params: exercise_params_with_tags)
  end

  def reload
    # Returns JSON with original file content
  end

  def statistics
    # Show general statistic page for specific exercise
    contributor_statistics = {InternalUser => {}, ExternalUser => {}, ProgrammingGroup => {}}

    query = SubmissionPolicy::DeadlineScope.new(current_user, Submission).resolve
      .select("contributor_id, contributor_type, MAX(score) AS maximum_score, COUNT(id) AS runs, MAX(created_at) FILTER (WHERE cause IN ('submit', 'assess', 'remoteSubmit', 'remoteAssess')) AS created_at, exercise_id")
      .where(exercise_id: @exercise.id)
      .group('contributor_id, contributor_type, exercise_id')
      .includes(:contributor, :exercise)

    query.each do |tuple|
      contributor_statistics[tuple.contributor_type.constantize][tuple.contributor] = tuple
    end

    render locals: {
      contributor_statistics:,
    }
  end

  def external_user_statistics
    # Render statistics page for one specific external user

    submissions = SubmissionPolicy::DeadlineScope.new(current_user, Submission).resolve
      .where(contributor: @external_user, exercise: @exercise)
      .order(submissions: {created_at: :desc})
      .includes(:exercise, testruns: [:testrun_messages, {file: [:file_type]}], files: [:file_type])

    if policy(@exercise).detailed_statistics?
      @show_autosaves = params[:show_autosaves] == 'true' || submissions.where.not(cause: 'autosave').none?

      interventions = @external_user.user_exercise_interventions.where(exercise: @exercise)
      @all_events = (submissions + interventions).sort_by(&:created_at)
      @deltas = @all_events.map.with_index do |item, index|
        delta = item.created_at - @all_events[index - 1].created_at if index.positive?
        delta.nil? || (delta > StatisticsHelper::WORKING_TIME_DELTA_IN_SECONDS) ? 0 : delta
      end
      @working_times_until = []
      @all_events.each_with_index do |_, index|
        @working_times_until.push(format_time_difference(@deltas[0..index].sum))
      end

      unless @show_autosaves
        # IMPORTANT: We always need to query the database for all submissions for the given external user and exercise.
        #            Otherwise, the working time estimation would be completely off and inaccurate.
        #            Consequentially, the 'show_autosaves' filter is applied here (not very nice, but it works).

        autosave_indices = @all_events.each_index.select {|i| @all_events[i].is_a?(Submission) && @all_events[i].cause == 'autosave' }

        # We need to delete from last to first (reverse), since we would otherwise change the indices of the following elements.
        autosave_indices.reverse_each do |index|
          @all_events.delete_at(index)
          @working_times_until.delete_at(index)
          # Hacky: If the autosave is the first element after a break, we need to set the delta of the following element to 0.
          # Since the @delta array is "broken" for filtered views anyway, we use this hack to get the red "highlight" line right.
          # TODO: Refactor the whole method into a more clean solution.
          @deltas[index + 1] = 0 if (@deltas[index]).zero? && @deltas[index + 1].present?
          @deltas.delete_at(index)
        end
      end
    else
      @all_events = submissions.sort_by(&:created_at)
    end

    render 'exercises/external_users/statistics'
  end

  def destroy
    destroy_and_respond(object: @exercise)
  end

  def study_group_dashboard
    authorize!
    @study_group_id = params[:study_group_id]
    @request_for_comments = RequestForComment
      .where(exercise: @exercise).includes(:submission)
      .where(submissions: {study_group_id: @study_group_id})
      .order(created_at: :desc)

    @graph_data = @exercise.get_working_times_for_study_group(@study_group_id)
  end
end
