class ExercisesController < ApplicationController
  include CommonBehavior
  include Lti
  include SubmissionParameters
  include SubmissionScoring

  before_action :handle_file_uploads, only: [:create, :update]
  before_action :set_execution_environments, only: [:create, :edit, :new, :update]
  before_action :set_exercise, only: MEMBER_ACTIONS + [:clone, :implement, :working_times, :intervention, :search, :run, :statistics, :submit, :reload, :feedback]
  before_action :set_external_user, only: [:statistics]
  before_action :set_file_types, only: [:create, :edit, :new, :update]
  before_action :set_course_token, only: [:implement]

  skip_before_filter :verify_authenticity_token, only: [:import_proforma_xml]
  skip_after_action :verify_authorized, only: [:import_proforma_xml]
  skip_after_action :verify_policy_scoped, only: [:import_proforma_xml]

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

  def java_course_token
    "702cbd2a-c84c-4b37-923a-692d7d1532d0"
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
    myparam = exercise_params
    checked_exercise_tags = @exercise_tags.select { | et | myparam[:tag_ids].include? et.tag.id.to_s }
    removed_exercise_tags = @exercise_tags.reject { | et | myparam[:tag_ids].include? et.tag.id.to_s }

    for et in checked_exercise_tags
      et.factor = params[:tag_factors][et.tag_id.to_s][:factor]
      et.exercise = @exercise
    end

    myparam[:exercise_tags] = checked_exercise_tags
    myparam.delete :tag_ids
    removed_exercise_tags.map {|et| et.destroy}

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
  end

  def import_proforma_xml
    begin
      user = user_for_oauth2_request()
      exercise = Exercise.new
      request_body = request.body.read
      exercise.from_proforma_xml(request_body)
      exercise.user = user
      saved = exercise.save
      if saved
        render :text => 'SUCCESS', :status => 200
      else
        logger.info(exercise.errors.full_messages)
        render :text => 'Invalid exercise', :status => 400
      end
    rescue => error
      if error.class == Hash
        render :text => error.message, :status => error.status
      else
        raise error
        render :text => '', :status => 500
      end
    end
  end

  def user_for_oauth2_request
    authorizationHeader = request.headers['Authorization']
    if authorizationHeader == nil
      raise ({status: 401, message: 'No Authorization header'})
    end

    oauth2Token = authorizationHeader.split(' ')[1]
    if oauth2Token == nil || oauth2Token.size == 0
      raise ({status: 401, message: 'No token in Authorization header'})
    end

    user = user_by_code_harbor_token(oauth2Token)
    if user == nil
      raise ({status: 401, message: 'Unknown OAuth2 token'})
    end

    return user
  end
  private :user_for_oauth2_request

  def user_by_code_harbor_token(oauth2Token)
    link = CodeHarborLink.where(:oauth2token => oauth2Token)[0]
    if link != nil
      return link.user
    end
  end
  private :user_by_code_harbor_token

  def exercise_params
    params[:exercise].permit(:description, :execution_environment_id, :file_id, :instructions, :public, :hide_file_tree, :allow_file_creation, :allow_auto_completion, :title, :expected_difficulty, files_attributes: file_attributes, :tag_ids => []).merge(user_id: current_user.id, user_type: current_user.class.name)
  end
  private :exercise_params

  def handle_file_uploads
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
  private :handle_file_uploads

  def implement
    redirect_to(@exercise, alert: t('exercises.implement.no_files')) unless @exercise.files.visible.exists?
    user_solved_exercise = @exercise.has_user_solved(current_user)
    count_interventions_today = UserExerciseIntervention.where(user: current_user).where("created_at >= ?", Time.zone.now.beginning_of_day).count
    user_got_intervention_in_exercise = UserExerciseIntervention.where(user: current_user, exercise: @exercise).size >= max_intervention_count_per_exercise
    user_got_enough_interventions = count_interventions_today >= max_intervention_count_per_day or user_got_intervention_in_exercise
    is_java_course = @course_token and @course_token.eql?(java_course_token)

    user_intervention_group = UserGroupSeparator.getInterventionGroup(current_user)

    case user_intervention_group
      when :no_intervention
      when :break_intervention
        @show_break_interventions = (not user_solved_exercise and is_java_course and not user_got_enough_interventions) ? "true" : "false"
      when :rfc_intervention
        @show_rfc_interventions = (not user_solved_exercise and is_java_course and not user_got_enough_interventions) ? "true" : "false"
    end

    @search = Search.new
    @search.exercise = @exercise
    @submission = current_user.submissions.where(exercise_id: @exercise.id).order('created_at DESC').first
    @files = (@submission ? @submission.collect_files : @exercise.files).select(&:visible).sort_by(&:name_with_extension)
    @paths = collect_paths(@files)

    if current_user.respond_to? :external_id
      @user_id = current_user.external_id
    else
      @user_id = current_user.id
    end
  end

  def set_course_token
    lti_parameters = LtiParameter.find_by(external_users_id: current_user.id,
                                          exercises_id: @exercise.id)
    if lti_parameters
      lti_json = lti_parameters.lti_parameters["launch_presentation_return_url"]

      @course_token =
          unless lti_json.nil?
            if match = lti_json.match(/^.*courses\/([a-z0-9\-]+)\/sections/)
              match.captures.first
            else
              ""
            end
          else
            ""
          end
    else
      # no consumer, therefore implementation with internal user
      @course_token = java_course_token
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
    unless intervention.nil?
      uei = UserExerciseIntervention.new(
          user: current_user, exercise: @exercise, intervention: intervention,
          accumulated_worktime_s: @exercise.accumulated_working_time_for_only(current_user))
      uei.save
      render(json: {success: 'true'})
    else
      render(json: {success: 'false', error: "undefined intervention #{params[:intervention_type]}"})
    end
  end

  def search
    search_text = params[:search_text]
    search = Search.new(user: current_user, exercise: @exercise, search: search_text)

    begin search.save
      render(json: {success: 'true'})
    rescue
      render(json: {success: 'false', error: "could not save search: #{$!}"})
    end
  end

  def index
    @search = policy_scope(Exercise).search(params[:q])
    @exercises = @search.result.includes(:execution_environment, :user).order(:title).paginate(page: params[:page])
    authorize!
  end

  def redirect_to_lti_return_path
    lti_parameter = LtiParameter.where(consumers_id: session[:consumer_id],
                                       external_users_id: @submission.user_id,
                                       exercises_id: @submission.exercise_id).first

    path = lti_return_path(consumer_id: session[:consumer_id],
                           submission_id: @submission.id,
                           url: consumer_return_url(build_tool_provider(consumer: Consumer.find_by(id: session[:consumer_id]),
                                                                        parameters: lti_parameter.lti_parameters)))
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

  def set_exercise
    @exercise = Exercise.find(params[:id])
    authorize!
  end
  private :set_exercise

  def set_external_user
    if params[:external_user_id]
      @external_user = ExternalUser.find(params[:external_user_id])
      authorize!
    end
  end
  private :set_exercise

  def set_file_types
    @file_types = FileType.all.order(:name)
  end
  private :set_file_types

  def collect_set_and_unset_exercise_tags
    @search = policy_scope(Tag).search(params[:q])
    @tags = @search.result.order(:name)
    checked_exercise_tags = @exercise.exercise_tags
    checked_tags = checked_exercise_tags.collect{|e| e.tag}.to_set
    unchecked_tags = Tag.all.to_set.subtract checked_tags
    @exercise_tags = checked_exercise_tags + unchecked_tags.collect { |tag| ExerciseTag.new(exercise: @exercise, tag: tag)}
  end
  private :collect_set_and_unset_exercise_tags

  def show
  end

  #we might want to think about auth here
  def reload
  end

  def statistics
    if(@external_user)
      render 'exercises/external_users/statistics'
    else
      user_statistics = {}
      query = "SELECT user_id, MAX(score) AS maximum_score, COUNT(id) AS runs
              FROM submissions WHERE exercise_id = #{@exercise.id} GROUP BY
              user_id;"
      ActiveRecord::Base.connection.execute(query).each do |tuple|
        user_statistics[tuple["user_id"].to_i] = tuple
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
    ::NewRelic::Agent.add_custom_attributes({ submission: @submission.id, normalized_score: @submission.normalized_score })
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
    checked_exercise_tags = @exercise_tags.select { | et | myparam[:tag_ids].include? et.tag.id.to_s }
    removed_exercise_tags = @exercise_tags.reject { | et | myparam[:tag_ids].include? et.tag.id.to_s }

    for et in checked_exercise_tags
      et.factor = params[:tag_factors][et.tag_id.to_s][:factor]
      et.exercise = @exercise
    end

    myparam[:exercise_tags] = checked_exercise_tags
    myparam.delete :tag_ids
    removed_exercise_tags.map {|et| et.destroy}
    update_and_respond(object: @exercise, params: myparam)
  end

  def redirect_after_submit
    Rails.logger.debug('Redirecting user with score:s ' + @submission.normalized_score.to_s)
    if @submission.normalized_score == 1.0
      # if user is external and has an own rfc, redirect to it and message him to clean up and accept the answer. (we need to check that the user is external,
      # otherwise an internal user could be shown a false rfc here, since current_user.id is polymorphic, but only makes sense for external users when used with rfcs.)
      # redirect 10 percent pseudorandomly to the feedback page
      if current_user.respond_to? :external_id
        if @submission.redirect_to_feedback?
          redirect_to_user_feedback
          return
        end

        rfc = @submission.own_unsolved_rfc
        if rfc
          # set a message that informs the user that his own RFC should be closed.
          flash[:notice] = I18n.t('exercises.submit.full_score_redirect_to_own_rfc')
          flash.keep(:notice)

          respond_to do |format|
            format.html { redirect_to(rfc) }
            format.json { render(json: {redirect: url_for(rfc)}) }
          end
          return
        end

        # else: show open rfc for same exercise if available
        rfc = @submission.unsolved_rfc
        unless rfc.nil?
          # set a message that informs the user that his score was perfect and help in RFC is greatly appreciated.
          flash[:notice] = I18n.t('exercises.submit.full_score_redirect_to_rfc')
          flash.keep(:notice)

          # increase counter 'times_featured' in rfc
          rfc.increment!(:times_featured)

          respond_to do |format|
            format.html {redirect_to(rfc)}
            format.json {render(json: {redirect: url_for(rfc)})}
          end
          return
        end
      end
    else
      # redirect to feedback page if score is less than 100 percent
       if @exercise.needs_more_feedback?
         redirect_to_user_feedback
       else
         redirect_to_lti_return_path
       end
       return
    end
    redirect_to_lti_return_path
  end

  def redirect_to_user_feedback
    url = if UserExerciseFeedback.find_by(exercise: @exercise, user: current_user)
            edit_user_exercise_feedback_path(user_exercise_feedback: {exercise_id: @exercise.id})
          else
            new_user_exercise_feedback_path(user_exercise_feedback: {exercise_id: @exercise.id})
          end

    respond_to do |format|
      format.html { redirect_to(url) }
      format.json { render(json: {redirect: url}) }
    end
  end

end
