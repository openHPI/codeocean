class HintsController < ApplicationController
  before_action :set_execution_environment
  before_action :set_hint, only: MEMBER_ACTIONS

  def authorize!
    authorize(@hint || @hints)
  end
  private :authorize!

  def create
    @hint = Hint.new(hint_params)
    authorize!
    respond_to do |format|
      if @hint.save
        format.html { redirect_to(execution_environment_hint_path(@execution_environment, @hint.id), notice: t('shared.object_created', model: Hint.model_name.human)) }
        format.json { render(:show, location: @hint, status: :created) }
      else
        format.html { render(:new) }
        format.json { render(json: @hint.errors, status: :unprocessable_entity) }
      end
    end
  end

  def destroy
    @hint.destroy
    respond_to do |format|
      format.html { redirect_to(execution_environment_hints_path(@execution_environment), notice: t('shared.object_destroyed', model: Hint.model_name.human)) }
      format.json { head(:no_content) }
    end
  end

  def edit
  end

  def hint_params
    params[:hint].permit(:locale, :message, :name, :regular_expression).merge(execution_environment_id: @execution_environment.id)
  end
  private :hint_params

  def index
    @hints = Hint.where(execution_environment_id: @execution_environment.id).order(:name)
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
    respond_to do |format|
      if @hint.update(hint_params)
        format.html { redirect_to(execution_environment_hint_path(params[:execution_environment_id], @hint.id), notice: t('shared.object_updated', model: Hint.model_name.human)) }
        format.json { render(:show, location: @hint, status: :ok) }
      else
        format.html { render(:edit) }
        format.json { render(json: @hint.errors, status: :unprocessable_entity) }
      end
    end
  end
end
