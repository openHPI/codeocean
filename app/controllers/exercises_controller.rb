class ExercisesController < ApplicationController
  include CommonBehavior
  include Lti
  include SubmissionParameters
  include SubmissionScoring

  before_action :handle_file_uploads, only: [:create, :update]
  before_action :set_execution_environments, only: [:create, :edit, :new, :update]
  before_action :set_exercise, only: MEMBER_ACTIONS + [:clone, :implement, :run, :statistics, :submit, :reload]
  before_action :set_external_user, only: [:statistics]
  before_action :set_file_types, only: [:create, :edit, :new, :update]

  skip_before_filter :verify_authenticity_token, only: [:import_proforma_xml]
  skip_after_action :verify_authorized, only: [:import_proforma_xml]
  skip_after_action :verify_policy_scoped, only: [:import_proforma_xml]

  def authorize!
    authorize(@exercise || @exercises)
  end
  private :authorize!

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
    authorize!
    create_and_respond(object: @exercise)
  end

  def destroy
    destroy_and_respond(object: @exercise)
  end

  def edit
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
    params[:exercise].permit(:description, :execution_environment_id, :file_id, :instructions, :public, :hide_file_tree, :allow_file_creation, :allow_auto_completion, :title, files_attributes: file_attributes).merge(user_id: current_user.id, user_type: current_user.class.name)
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
    @submission = current_user.submissions.where(exercise_id: @exercise.id).order('created_at DESC').first
    @files = (@submission ? @submission.collect_files : @exercise.files).select(&:visible).sort_by(&:name_with_extension)
    @paths = collect_paths(@files)

    if current_user.respond_to? :external_id
      @user_id = current_user.external_id
    else
      @user_id = current_user.id
    end
  end

  def index
    @search = policy_scope(Exercise).search(params[:q])
    @exercises = @search.result.includes(:execution_environment, :user).order(:title).paginate(page: params[:page])
    authorize!
  end

  def redirect_to_lti_return_path
    #Todo replace session with lti_parameter /done
    lti_parameter = LtiParameter.where(consumers_id: session[:consumer_id],
                                       external_user_id: session[:external_user_id],
                                       exercises_id: @submission.exercise_id).first

    path = lti_return_path(consumer_id: session[:consumer_id],
                           submission_id: @submission.id,
                           url: consumer_return_url(build_tool_provider(consumer: Consumer.find_by(id: session[:consumer_id]),
                                                                        parameters: lti_parameter.lti_parameters)))
                                                                        # parameters: session[:lti_parameters])))
    respond_to do |format|
      format.html { redirect_to(path) }
      format.json { render(json: {redirect: path}) }
    end
  end
  private :redirect_to_lti_return_path

  def new
    @exercise = Exercise.new
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
    if lti_outcome_service?(@submission.exercise_id)
      transmit_lti_score
    else
      redirect_after_submit
    end
  end

  def transmit_lti_score
    ::NewRelic::Agent.add_custom_parameters({ submission: @submission.id, normalized_score: @submission.normalized_score })
    response = send_score(@submission.exercise_id, @submission.normalized_score)

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
    update_and_respond(object: @exercise, params: exercise_params)
  end

  def redirect_after_submit
    Rails.logger.debug('Redirecting user with score:s ' + @submission.normalized_score.to_s)
    if @submission.normalized_score == 1.0
      # if user is external and has an own rfc, redirect to it and message him to clean up and accept the answer. (we need to check that the user is external,
      # otherwise an internal user could be shown a false rfc here, since current_user.id is polymorphic, but only makes sense for external users when used with rfcs.)
      if current_user.respond_to? :external_id
        if rfc = RequestForComment.unsolved.where(exercise_id: @submission.exercise, user_id: current_user.id).first
          # set a message that informs the user that his own RFC should be closed.
          flash[:notice] = I18n.t('exercises.submit.full_score_redirect_to_own_rfc')
          flash.keep(:notice)

          respond_to do |format|
            format.html { redirect_to(rfc) }
            format.json { render(json: {redirect: url_for(rfc)}) }
          end
          return

        # else: show open rfc for same exercise if available
        elsif rfc = RequestForComment.unsolved.where(exercise_id: @submission.exercise).where.not(question: nil).order("RANDOM()").first
          # set a message that informs the user that his score was perfect and help in RFC is greatly appreciated.
          flash[:notice] = I18n.t('exercises.submit.full_score_redirect_to_rfc')
          flash.keep(:notice)

          respond_to do |format|
            format.html { redirect_to(rfc) }
            format.json { render(json: {redirect: url_for(rfc)}) }
          end
          return
        end
      end
    end
    redirect_to_lti_return_path
  end

end
