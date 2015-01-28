class TeamsController < ApplicationController
  before_action :set_team, only: MEMBER_ACTIONS

  def authorize!
    authorize(@team || @teams)
  end
  private :authorize!

  def create
    @team = Team.new(team_params)
    authorize!
    respond_to do |format|
      if @team.save
        format.html { redirect_to(team_path(@team.id), notice: t('shared.object_created', model: Team.model_name.human)) }
        format.json { render(:show, location: @team, status: :created) }
      else
        format.html { render(:new) }
        format.json { render(json: @team.errors, status: :unprocessable_entity) }
      end
    end
  end

  def destroy
    @team.destroy
    respond_to do |format|
      format.html { redirect_to(teams_path, notice: t('shared.object_destroyed', model: Team.model_name.human)) }
      format.json { head(:no_content) }
    end
  end

  def edit
  end

  def index
    @teams = Team.all.order(:name)
    authorize!
  end

  def new
    @team = Team.new
    authorize!
  end

  def set_team
    @team = Team.find(params[:id])
    authorize!
  end
  private :set_team

  def show
  end

  def team_params
    params[:team].permit(:name, internal_user_ids: [])
  end
  private :team_params

  def update
    respond_to do |format|
      if @team.update(team_params)
        format.html { redirect_to(team_path(@team.id), notice: t('shared.object_updated', model: Team.model_name.human)) }
        format.json { render(:show, location: @team, status: :ok) }
      else
        format.html { render(:edit) }
        format.json { render(json: @team.errors, status: :unprocessable_entity) }
      end
    end
  end
end
