class HintsController < ApplicationController
  include CommonBehavior

  before_action :set_execution_environment
  before_action :set_hint, only: MEMBER_ACTIONS

  def authorize!
    authorize(@hint || @hints)
  end
  private :authorize!

  def create
    @hint = Hint.new(hint_params)
    authorize!
    create_and_respond(object: @hint, path: proc { execution_environment_hint_path(@execution_environment, @hint) })
  end

  def destroy
    destroy_and_respond(object: @hint, path: execution_environment_hints_path(@execution_environment))
  end

  def edit
  end

  def hint_params
    params[:hint].permit(:locale, :message, :name, :regular_expression).merge(execution_environment_id: @execution_environment.id)
  end
  private :hint_params

  def index
    @hints = @execution_environment.hints.order(:name).paginate(page: params[:page])
    authorize!
  end

  def new
    @hint = Hint.new
    authorize!
  end

  def set_execution_environment
    @execution_environment = ExecutionEnvironment.find(params[:execution_environment_id])
  end
  private :set_execution_environment

  def set_hint
    @hint = Hint.find(params[:id])
    authorize!
  end
  private :set_hint

  def show
  end

  def update
    update_and_respond(object: @hint, params: hint_params, path: execution_environment_hint_path(@execution_environment, @hint))
  end
end
