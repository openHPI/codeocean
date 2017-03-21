class InterventionsController < ApplicationController
  include CommonBehavior

  before_action :set_intervention, only: MEMBER_ACTIONS

  def authorize!
    authorize(@intervention || @interventions)
  end
  private :authorize!

  def create
    #@intervention = Intervention.new(intervention_params)
    #authorize!
    #create_and_respond(object: @intervention)
  end

  def destroy
    destroy_and_respond(object: @intervention)
  end

  def edit
  end

  def intervention_params
    params[:intervention].permit(:name)
  end
  private :intervention_params

  def index
    @interventions = Intervention.all.paginate(page: params[:page])
    authorize!
  end

  def new
    #@intervention = Intervention.new
    #authorize!
  end

  def set_intervention
    @intervention = Intervention.find(params[:id])
    authorize!
  end
  private :set_intervention

  def show
  end

  def update
    update_and_respond(object: @intervention, params: intervention_params)
  end

  def to_s
    name
  end
end
