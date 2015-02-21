class ExercisesController < ApplicationController
  include CommonBehavior
  include Lti
  include SubmissionParameters
  include SubmissionScoring

  before_action :handle_file_uploads, only: [:create, :update]
  before_action :set_execution_environments, only: [:create, :edit, :new, :update]
  before_action :set_exercise, only: MEMBER_ACTIONS + [:clone, :implement, :run, :statistics, :submit]
  before_action :set_file_types, only: [:create, :edit, :new, :update]
  before_action :set_teams, only: [:create, :edit, :new, :update]

  def authorize!
    authorize(@exercise || @exercises)
  end
  private :authorize!

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

  def exercise_params
    params[:exercise].permit(:description, :execution_environment_id, :file_id, :instructions, :public, :team_id, :title, files_attributes: file_attributes).merge(user_id: current_user.id, user_type: current_user.class.name)
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
    @submission = Submission.where(exercise_id: @exercise.id, user_id: current_user.id).order('created_at DESC').first
    @files = (@submission ? @submission.collect_files : @exercise.files).select(&:visible).sort_by(&:name_with_extension)
  end

  def index
    @search = policy_scope(Exercise).search(params[:q])
    @exercises = @search.result.order(:title)
    authorize!
  end

  def redirect_to_lti_return_path
    path = lti_return_path(consumer_id: session[:consumer_id], submission_id: @submission.id, url: consumer_return_url(build_tool_provider(consumer: Consumer.find_by(id: session[:consumer_id]), parameters: session[:lti_parameters])))
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

  def set_file_types
    @file_types = FileType.all.order(:name)
  end
  private :set_file_types

  def set_teams
    @teams = Team.all.order(:name)
  end
  private :set_teams

  def show
  end

  def statistics
  end

  def submit
    @submission = Submission.create(submission_params)
    score_submission(@submission)
    if lti_outcome_service?
      transmit_lti_score
    else
      redirect_to_lti_return_path
    end
  end

  def transmit_lti_score
    response = send_score(@submission.normalized_score)
    if response[:status] == 'success'
      redirect_to_lti_return_path
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
end
