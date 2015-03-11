class TeamsController < ApplicationController
  include CommonBehavior

  before_action :set_team, only: MEMBER_ACTIONS

  def authorize!
    authorize(@team || @teams)
  end
  private :authorize!

  def create
    @team = Team.new(team_params)
    authorize!
    create_and_respond(object: @team)
  end

  def destroy
    destroy_and_respond(object: @team)
  end

  def edit
  end

  def index
    @teams = Team.all.includes(:internal_users).order(:name).paginate(page: params[:page])
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
    update_and_respond(object: @team, params: team_params)
  end
end
