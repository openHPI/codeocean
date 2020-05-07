# frozen_string_literal: true

class ExercisesController < ApplicationController
  include CommonBehavior
  include Lti
  include SubmissionParameters
  include SubmissionScoring
  include TimeHelper

  before_action :handle_file_uploads, only: %i[create update]
  before_action :set_execution_environments, only: %i[create edit new update]
  before_action :set_exercise_and_authorize, only: MEMBER_ACTIONS + %i[clone implement working_times intervention search run statistics submit reload feedback requests_for_comments study_group_dashboard export_external_check export_external_confirm]
  before_action :set_external_user_and_authorize, only: [:statistics]
  before_action :set_file_types, only: %i[create edit new update]
  before_action :set_course_token, only: [:implement]

  skip_before_action :verify_authenticity_token, only: %i[import_exercise import_uuid_check export_external_confirm]
  skip_after_action :verify_authorized, only: %i[import_exercise import_uuid_check export_external_confirm]
  skip_after_action :verify_policy_scoped, only: %i[import_exercise import_uuid_check export_external_confirm], raise: false

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

  def experimental_courses
    {
      java17: '702cbd2a-c84c-4b37-923a-692d7d1532d0',
      java1: '0ea88ea9-979a-44a3-b0e4-84ba58e5a05e'
    }
  end

  def experimental_course?(course_token)
    experimental_courses.value?(course_token)
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
      redirect_to(exercise, notice: t('shared.object_cloned', model: Exercise.model_name.human))
    else
      flash[:danger] = t('shared.message_failure')
      redirect_to(@exercise)
    end
  end

  def collect_paths(files)
    unique_paths = files.map(&:path).reject(&:blank?).uniq
    subpaths = unique_paths.map do |path|
      (path.split('/').length + 1).times.map do |n|
        path.split('/').shift(n).join('/')
      end
    end
    subpaths.flatten.uniq
  end
  private :collect_paths

  def create
    @exercise = Exercise.new(exercise_params)
    collect_set_and_unset_exercise_tags
    myparam = exercise_params.present? ? exercise_params : {}
    checked_exercise_tags = @exercise_tags.select { |et| myparam[:tag_ids].include? et.tag.id.to_s }
    removed_exercise_tags = @exercise_tags.reject { |et| myparam[:tag_ids].include? et.tag.id.to_s }

    checked_exercise_tags.each do |et|
      et.factor = params[:tag_factors][et.tag_id.to_s][:factor]
      et.exercise = @exercise
    end

    myparam[:exercise_tags] = checked_exercise_tags
    myparam.delete :tag_ids
    removed_exercise_tags.map(&:destroy)

    authorize!
    create_and_respond(object: @exercise)
  end

  def destroy
    destroy_and_respond(object: @exercise)
  end

  def edit
    collect_set_and_unset_exercise_tags
  end

  def feedback
    authorize!
    @feedbacks = @exercise.user_exercise_feedbacks.paginate(page: params[:page])
    @submissions = @feedbacks.map do |feedback|
      feedback.exercise.final_submission(feedback.user)
    end
  end

  def requests_for_comments
    authorize!
    @search = RequestForComment
              .with_last_activity
              .where(exercise: @exercise)
              .ransack(params[:q])
    @request_for_comments = @search.result
                                   .order('last_comment DESC')
                                   .paginate(page: params[:page])
    render 'request_for_comments/index'
  end

  def export_external_check
    codeharbor_check = ExerciseService::CheckExternal.call(uuid: @exercise.uuid, codeharbor_link: current_user.codeharbor_link)
    render json: {
      message: codeharbor_check[:message],
      actions: render_to_string(
        partial: 'export_actions',
        locals: {
          exercise: @exercise,
          exercise_found: codeharbor_check[:exercise_found],
          update_right: codeharbor_check[:update_right],
          error: codeharbor_check[:error],
          exported: false
        }
      )
    }, status: 200
  end

  def export_external_confirm
    @exercise.uuid = SecureRandom.uuid if @exercise.uuid.nil?

    error = ExerciseService::PushExternal.call(
      zip: ProformaService::ExportTask.call(exercise: @exercise),
      codeharbor_link: current_user.codeharbor_link
    )
    if error.nil?
      render json: {
        status: 'success',
        message: t('exercises.export_codeharbor.successfully_exported', id: @exercise.id, title: @exercise.title),
        actions: render_to_string(partial: 'export_actions', locals: {exercise: @exercise, exported: true, error: error})
      }
      @exercise.save
    else
      render json: {
        status: 'fail',
        message: t('exercises.export_codeharbor.export_failed', id: @exercise.id, title: @exercise.title, error: error),
        actions: render_to_string(partial: 'export_actions', locals: {exercise: @exercise, exported: true, error: error})
      }
    end
  end

  def import_uuid_check
    user = user_from_api_key
    return render json: {}, status: 401 if user.nil?

    uuid = params[:uuid]
    exercise = Exercise.find_by(uuid: uuid)

    return render json: {exercise_found: false} if exercise.nil?
    return render json: {exercise_found: true, update_right: false} unless ExercisePolicy.new(user, exercise).update?

    render json: {exercise_found: true, update_right: true}
  end

  def import_exercise
    tempfile = Tempfile.new('codeharbor_import.zip')
    tempfile.write request.body.read.force_encoding('UTF-8')
    tempfile.rewind

    user = user_from_api_key
    return render json: {}, status: 401 if user.nil?

    exercise = nil
    ActiveRecord::Base.transaction do
      exercise = ::ProformaService::Import.call(zip: tempfile, user: user)
      exercise.save!
      return render json: {}, status: 201
    end
  rescue Proforma::ExerciseNotOwned
    render json: {}, status: 401
  rescue Proforma::ProformaError
    render json: t('exercises.import_codeharbor.import_errors.invalid'), status: 400
  rescue StandardError
    render json: t('exercises.import_codeharbor.import_errors.internal_error'), status: 500
  end

  def user_from_api_key
    authorization_header = request.headers['Authorization']
    api_key = authorization_header&.split(' ')&.second
    user_by_codeharbor_token(api_key)
  end
  private :user_from_api_key

  def user_by_codeharbor_token(api_key)
    link = CodeharborLink.find_by_api_key(api_key)
    link&.user
  end
  private :user_by_codeharbor_token

  def exercise_params
    params[:exercise].permit(:description, :execution_environment_id, :file_id, :instructions, :submission_deadline, :late_submission_deadline, :public, :unpublished, :hide_file_tree, :allow_file_creation, :allow_auto_completion, :title, :expected_difficulty, files_attributes: file_attributes, tag_ids: []).merge(user_id: current_user.id, user_type: current_user.class.name) if params[:exercise].present?
  end
  private :exercise_params

  def handle_file_uploads
    if exercise_params
      exercise_params[:files_attributes].try(:each) do |index, file_attributes|
        if file_attributes[:content].respond_to?(:read)
          file_params = params[:exercise][:files_attributes][index]
          if FileType.find_by(id: file_attributes[:file_type_id]).try(:binary?)
            file_params[:content] = nil
            file_params[:native_file] = file_attributes[:content]
          else
            file_params[:content] = file_attributes[:content].read
          end
        end
      end
    end
  end
  private :handle_file_uploads

  def implement
    redirect_to(@exercise, alert: t('exercises.implement.unpublished')) if @exercise.unpublished? && current_user.role != 'admin' && current_user.role != 'teacher' # TODO: TESTESTEST
    redirect_to(@exercise, alert: t('exercises.implement.no_files')) unless @exercise.files.visible.exists?
    user_solved_exercise = @exercise.has_user_solved(current_user)
    count_interventions_today = UserExerciseIntervention.where(user: current_user).where('created_at >= ?', Time.zone.now.beginning_of_day).count
    user_got_intervention_in_exercise = UserExerciseIntervention.where(user: current_user, exercise: @exercise).size >= max_intervention_count_per_exercise
    (user_got_enough_interventions = count_interventions_today >= max_intervention_count_per_day) || user_got_intervention_in_exercise

    if @embed_options[:disable_interventions]
      @show_rfc_interventions = false
      @show_break_interventions = false
    else
      @show_rfc_interventions = (!user_solved_exercise && !user_got_enough_interventions).to_s
      @show_break_interventions = false
    end

    @hide_rfc_button = @embed_options[:disable_rfc]

    @search = Search.new
    @search.exercise = @exercise
    @submission = current_user.submissions.where(exercise_id: @exercise.id).order('created_at DESC').first
    @files = (@submission ? @submission.collect_files : @exercise.files).select(&:visible).sort_by(&:name_with_extension)
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
        if lti_json.nil?
          ''
        else
          if match = lti_json.match(%r{^.*courses/([a-z0-9\-]+)/sections})
            match.captures.first
          else
            ''
          end
        end
    else
      # no consumer, therefore implementation with internal user
      @course_token = '702cbd2a-c84c-4b37-923a-692d7d1532d0'
    end
  end
  private :set_course_token

  def working_times
    working_time_accumulated = @exercise.accumulated_working_time_for_only(current_user)
    working_time_75_percentile = @exercise.get_quantiles([0.75]).first
    render(json: {working_time_75_percentile: working_time_75_percentile, working_time_accumulated: working_time_accumulated})
  end

  def intervention
    intervention = Intervention.find_by_name(params[:intervention_type])
    if intervention.nil?
      render(json: {success: 'false', error: "undefined intervention #{params[:intervention_type]}"})
    else
      uei = UserExerciseIntervention.new(
        user: current_user, exercise: @exercise, intervention: intervention,
        accumulated_worktime_s: @exercise.accumulated_working_time_for_only(current_user)
      )
      uei.save
      render(json: {success: 'true'})
    end
  end

  def search
    search_text = params[:search_text]
    search = Search.new(user: current_user, exercise: @exercise, search: search_text)

    begin search.save
          render(json: {success: 'true'})
    rescue StandardError
      render(json: {success: 'false', error: "could not save search: #{$ERROR_INFO}"})
    end
  end

  def index
    @search = policy_scope(Exercise).ransack(params[:q])
    @exercises = @search.result.includes(:execution_environment, :user).order(:title).paginate(page: params[:page])
    authorize!
  end

  def redirect_to_lti_return_path
    Raven.extra_context(
      consumers_id: session[:consumer_id],
      external_users_id: @submission.user_id,
      exercises_id: @submission.exercise_id,
      session: session.to_hash,
      submission: @submission.inspect,
      params: params.as_json,
      current_user: current_user,
      lti_exercise_id: session[:lti_exercise_id],
      lti_parameters_id: session[:lti_parameters_id]
    )

    lti_parameter = LtiParameter.where(consumers_id: session[:consumer_id],
                                       external_users_id: @submission.user_id,
                                       exercises_id: @submission.exercise_id).last

    path = lti_return_path(consumer_id: session[:consumer_id],
                           submission_id: @submission.id,
                           url: consumer_return_url(build_tool_provider(consumer: Consumer.find_by(id: session[:consumer_id]),
                                                                        parameters: lti_parameter.lti_parameters)))
    clear_lti_session_data(@submission.exercise_id, @submission.user_id, session[:consumer_id])
    respond_to do |format|
      format.html { redirect_to(path) }
      format.json { render(json: {redirect: path}) }
    end
  end
  private :redirect_to_lti_return_path

  def new
    @exercise = Exercise.new
    collect_set_and_unset_exercise_tags

    authorize!
  end

  def set_execution_environments
    @execution_environments = ExecutionEnvironment.all.order(:name)
  end
  private :set_execution_environments

  def set_exercise_and_authorize
    @exercise = Exercise.find(params[:id])
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
    @search = policy_scope(Tag).ransack(params[:q])
    @tags = @search.result.order(:name)
    checked_exercise_tags = @exercise.exercise_tags
    checked_tags = checked_exercise_tags.collect(&:tag).to_set
    unchecked_tags = Tag.all.to_set.subtract checked_tags
    @exercise_tags = checked_exercise_tags + unchecked_tags.collect { |tag| ExerciseTag.new(exercise: @exercise, tag: tag) }
  end
  private :collect_set_and_unset_exercise_tags

  def show
    # Show exercise details for teachers and admins
  end

  def reload
    # Returns JSON with original file content
  end

  def statistics
    if @external_user
      authorize(@external_user, :statistics?)
      if policy(@exercise).detailed_statistics?
        @submissions = Submission.where(user: @external_user, exercise_id: @exercise.id).in_study_group_of(current_user).order('created_at')
        interventions = UserExerciseIntervention.where('user_id = ?  AND exercise_id = ?', @external_user.id, @exercise.id)
        @all_events = (@submissions + interventions).sort_by(&:created_at)
        @deltas = @all_events.map.with_index do |item, index|
          delta = item.created_at - @all_events[index - 1].created_at if index > 0
          delta.nil? || (delta > StatisticsHelper::WORKING_TIME_DELTA_IN_SECONDS) ? 0 : delta
        end
        @working_times_until = []
        @all_events.each_with_index do |_, index|
          @working_times_until.push((format_time_difference(@deltas[0..index].inject(:+)) if index > 0))
        end
      else
        latest_submissions = Submission.where(user: @external_user, exercise_id: @exercise.id).in_study_group_of(current_user).final.latest
        relevant_submissions = latest_submissions.before_deadline.or(latest_submissions.within_grace_period).or(latest_submissions.after_late_deadline)
        @submissions = relevant_submissions.sort_by(&:created_at)
        @all_events = @submissions
      end
      render 'exercises/external_users/statistics'
    else
      user_statistics = {}
      additional_filter = if policy(@exercise).detailed_statistics?
                            ''
                          else
                            "AND study_group_id IN (#{current_user.study_groups.pluck(:id).join(', ')}) AND cause = 'submit'"
                          end
      query = "SELECT user_id, MAX(score) AS maximum_score, COUNT(id) AS runs
              FROM submissions WHERE exercise_id = #{@exercise.id} #{additional_filter} GROUP BY
              user_id;"
      ApplicationRecord.connection.execute(query).each do |tuple|
        user_statistics[tuple['user_id'].to_i] = tuple
      end
      render locals: {
        user_statistics: user_statistics
      }
    end
  end

  def submit
    @submission = Submission.create(submission_params)
    score_submission(@submission)
    current_user = ExternalUser.find(@submission.user_id)
    if !current_user.nil? && lti_outcome_service?(@submission.exercise_id, current_user.id, current_user.consumer_id)
      transmit_lti_score
    else
      redirect_after_submit
    end
  end

  def transmit_lti_score
    ::NewRelic::Agent.add_custom_attributes({submission: @submission.id, normalized_score: @submission.normalized_score})
    response = send_score(@submission.exercise_id, @submission.normalized_score, @submission.user_id)

    if response[:status] == 'success'
      redirect_after_submit
    else
      respond_to do |format|
        format.html { redirect_to(implement_exercise_path(@submission.exercise)) }
        format.json { render(json: {message: I18n.t('exercises.submit.failure')}, status: 503) }
      end
    end
  end
  private :transmit_lti_score

  def update
    collect_set_and_unset_exercise_tags
    myparam = exercise_params
    checked_exercise_tags = @exercise_tags.select { |et| myparam[:tag_ids].include? et.tag.id.to_s }
    removed_exercise_tags = @exercise_tags.reject { |et| myparam[:tag_ids].include? et.tag.id.to_s }

    checked_exercise_tags.each do |et|
      et.factor = params[:tag_factors][et.tag_id.to_s][:factor]
      et.exercise = @exercise
    end

    myparam[:exercise_tags] = checked_exercise_tags
    myparam.delete :tag_ids
    removed_exercise_tags.map(&:destroy)
    update_and_respond(object: @exercise, params: myparam)
  end

  def redirect_after_submit
    Rails.logger.debug('Redirecting user with score:s ' + @submission.normalized_score.to_s)
    if @submission.normalized_score == 1.0
      # if user is external and has an own rfc, redirect to it and message him to clean up and accept the answer. (we need to check that the user is external,
      # otherwise an internal user could be shown a false rfc here, since current_user.id is polymorphic, but only makes sense for external users when used with rfcs.)
      # redirect 10 percent pseudorandomly to the feedback page
      if current_user.respond_to? :external_id
        if @submission.redirect_to_feedback? && !@embed_options[:disable_redirect_to_feedback]
          clear_lti_session_data(@submission.exercise_id, @submission.user_id, session[:consumer_id])
          redirect_to_user_feedback
          return
        end

        rfc = @submission.own_unsolved_rfc
        if rfc
          # set a message that informs the user that his own RFC should be closed.
          flash[:notice] = I18n.t('exercises.submit.full_score_redirect_to_own_rfc')
          flash.keep(:notice)

          clear_lti_session_data(@submission.exercise_id, @submission.user_id, session[:consumer_id])
          respond_to do |format|
            format.html { redirect_to(rfc) }
            format.json { render(json: {redirect: url_for(rfc)}) }
          end
          return
        end

        # else: show open rfc for same exercise if available
        rfc = @submission.unsolved_rfc
        unless rfc.nil? || @embed_options[:disable_redirect_to_rfcs] || @embed_options[:disable_rfc]
          # set a message that informs the user that his score was perfect and help in RFC is greatly appreciated.
          flash[:notice] = I18n.t('exercises.submit.full_score_redirect_to_rfc')
          flash.keep(:notice)

          # increase counter 'times_featured' in rfc
          rfc.increment!(:times_featured)

          clear_lti_session_data(@submission.exercise_id, @submission.user_id, session[:consumer_id])
          respond_to do |format|
            format.html { redirect_to(rfc) }
            format.json { render(json: {redirect: url_for(rfc)}) }
          end
          return
        end
      end
    else
      # redirect to feedback page if score is less than 100 percent
      if @exercise.needs_more_feedback? && !@embed_options[:disable_redirect_to_feedback]
        clear_lti_session_data(@submission.exercise_id, @submission.user_id, session[:consumer_id])
        redirect_to_user_feedback
      else
        redirect_to_lti_return_path
      end
      return
    end
    redirect_to_lti_return_path
  end

  def redirect_to_user_feedback
    uef = UserExerciseFeedback.find_by(exercise: @exercise, user: current_user)
    url = if uef
            edit_user_exercise_feedback_path(uef)
          else
            new_user_exercise_feedback_path(user_exercise_feedback: {exercise_id: @exercise.id})
          end

    respond_to do |format|
      format.html { redirect_to(url) }
      format.json { render(json: {redirect: url}) }
    end
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
