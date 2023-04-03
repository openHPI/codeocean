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
    only: MEMBER_ACTIONS + %i[clone implement working_times intervention search run statistics submit reload feedback
                              requests_for_comments study_group_dashboard export_external_check export_external_confirm
                              external_user_statistics]
  before_action :collect_set_and_unset_exercise_tags, only: MEMBER_ACTIONS
  before_action :set_external_user_and_authorize, only: [:external_user_statistics]
  before_action :set_file_types, only: %i[create edit new update]
  before_action :set_course_token, only: [:implement]
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
    @exercises = Exercise.all
    authorize!
    @exercises = params[:exercises].values.map do |exercise_params|
      exercise = Exercise.find(exercise_params.delete(:id))
      exercise.update(exercise_params)
      exercise
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
    @feedbacks = @exercise.user_exercise_feedbacks.paginate(page: params[:page], per_page: per_page_param)
    @submissions = @feedbacks.map do |feedback|
      feedback.exercise.final_submission(feedback.user)
    end
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
  rescue Proforma::ExerciseNotOwned
    render json: {}, status: :unauthorized
  rescue Proforma::ProformaError
    render json: t('exercises.import_codeharbor.import_errors.invalid'), status: :bad_request
  rescue StandardError => e
    Sentry.capture_exception(e)
    render json: t('exercises.import_codeharbor.import_errors.internal_error'), status: :internal_server_error
  end

  def user_from_api_key
    authorization_header = request.headers['Authorization']
    api_key = authorization_header&.split(' ')&.second
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
                             :expected_difficulty,
                             :tips,
                             files_attributes: file_attributes,
                             tag_ids: []
                           ).merge(
                             user_id: current_user.id,
                             user_type: current_user.class.name
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

  def implement
    user_solved_exercise = @exercise.solved_by?(current_user)
    count_interventions_today = UserExerciseIntervention.where(user: current_user).where('created_at >= ?',
      Time.zone.now.beginning_of_day).count
    user_got_intervention_in_exercise = UserExerciseIntervention.where(user: current_user,
      exercise: @exercise).size >= max_intervention_count_per_exercise
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

    @search = Search.new
    @search.exercise = @exercise
    @submission = current_user.submissions.where(exercise_id: @exercise.id).order('created_at DESC').first
    @files = (@submission ? @submission.collect_files : @exercise.files).select(&:visible).sort_by(&:filepath)
    @paths = collect_paths(@files)

    @user_id = if current_user.respond_to? :external_id
                 current_user.external_id
               else
                 current_user.id
               end
  end

  def set_course_token
    lti_parameters = LtiParameter.where(external_users_id: current_user.id,
      exercises_id: @exercise.id).last
    if lti_parameters
      lti_json = lti_parameters.lti_parameters['launch_presentation_return_url']

      @course_token =
        if lti_json.present? && (match = lti_json.match(%r{^.*courses/([a-z0-9-]+)/sections}))
          match.captures.first
        else
          ''
        end
    else
      # no consumer, therefore implementation with internal user
      @course_token = '702cbd2a-c84c-4b37-923a-692d7d1532d0'
    end
  end

  private :set_course_token

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
    working_time_accumulated = @exercise.accumulated_working_time_for_only(current_user)
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
        user: current_user, exercise: @exercise, intervention:,
        accumulated_worktime_s: @exercise.accumulated_working_time_for_only(current_user)
      )
      uei.save
      render(json: {success: 'true'})
    end
  end

  def search
    search_text = params[:search_text]
    search = Search.new(user: current_user, exercise: @exercise, search: search_text)

    begin
      search.save
      render(json: {success: 'true'})
    rescue StandardError
      render(json: {success: 'false', error: "could not save search: #{$ERROR_INFO}"})
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
    end
  end

  def not_authorized_for_exercise(_exception)
    return render_not_authorized unless current_user
    return render_not_authorized unless %w[implement working_times intervention search reload].include?(action_name)

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
    @execution_environments = ExecutionEnvironment.all.order(:name)
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
    @file_types = FileType.all.order(:name)
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
    user_statistics = {'InternalUser' => {}, 'ExternalUser' => {}}

    query = Submission.select('user_id, user_type, MAX(score) AS maximum_score, COUNT(id) AS runs')
      .where(exercise_id: @exercise.id)
      .group('user_id, user_type')

    query = if policy(@exercise).detailed_statistics?
              query
            elsif !policy(@exercise).detailed_statistics? && current_user.study_groups.count.positive?
              query.where(study_groups: current_user.study_groups.pluck(:id), cause: 'submit')
            else
              # e.g. internal user without any study groups, show no submissions
              query.where('false')
            end

    query.each do |tuple|
      user_statistics[tuple['user_type']][tuple['user_id'].to_i] = tuple
    end

    render locals: {
      user_statistics:,
    }
  end

  def external_user_statistics
    # Render statistics page for one specific external user

    if policy(@exercise).detailed_statistics?
      submissions = Submission.where(user: @external_user, exercise: @exercise)
        .in_study_group_of(current_user)
        .order('created_at')
      @show_autosaves = params[:show_autosaves] == 'true' || submissions.none? {|s| s.cause != 'autosave' }
      submissions = submissions.where.not(cause: 'autosave') unless @show_autosaves
      interventions = UserExerciseIntervention.where('user_id = ?  AND exercise_id = ?', @external_user.id,
        @exercise.id)
      @all_events = (submissions + interventions).sort_by(&:created_at)
      @deltas = @all_events.map.with_index do |item, index|
        delta = item.created_at - @all_events[index - 1].created_at if index.positive?
        delta.nil? || (delta > StatisticsHelper::WORKING_TIME_DELTA_IN_SECONDS) ? 0 : delta
      end
      @working_times_until = []
      @all_events.each_with_index do |_, index|
        @working_times_until.push((format_time_difference(@deltas[0..index].sum) if index.positive?))
      end
    else
      final_submissions = Submission.where(user: @external_user,
        exercise_id: @exercise.id).in_study_group_of(current_user).final
      submissions = []
      %i[before_deadline within_grace_period after_late_deadline].each do |filter|
        relevant_submission = final_submissions.send(filter).latest
        submissions.push relevant_submission if relevant_submission.present?
      end
      @all_events = submissions
    end

    render 'exercises/external_users/statistics'
  end

  def submit
    @submission = Submission.create(submission_params)
    @submission.calculate_score
    if @submission.user.external_user? && lti_outcome_service?(@submission.exercise_id, @submission.user.id)
      transmit_lti_score
    else
      redirect_after_submit
    end
  rescue Runner::Error => e
    Rails.logger.debug { "Runner error while submitting submission #{@submission.id}: #{e.message}" }
    respond_to do |format|
      format.html { redirect_to(implement_exercise_path(@submission.exercise)) }
      format.json { render(json: {message: I18n.t('exercises.editor.depleted'), status: :container_depleted}) }
    end
  end

  def transmit_lti_score
    response = send_score(@submission)

    if response[:status] == 'success'
      if response[:score_sent] != @submission.normalized_score
        # Score has been reduced due to the passed deadline
        flash.now[:warning] = I18n.t('exercises.submit.too_late')
        flash.keep(:warning)
      end
      redirect_after_submit
    else
      respond_to do |format|
        format.html { redirect_to(implement_exercise_path(@submission.exercise, alert: I18n.t('exercises.submit.failure'))) }
        format.json { render(json: {message: I18n.t('exercises.submit.failure')}, status: :service_unavailable) }
      end
    end
  end

  private :transmit_lti_score

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
