class CodeharborLinksController < ApplicationController
  include CommonBehavior
  before_action :set_codeharbor_link, only: [:show, :edit, :update, :destroy]

  def authorize!
    authorize(@codeharbor_link || @codeharbor_links)
  end
  private :authorize!

  def index
    @codeharbor_links = CodeharborLink.where(user_id: current_user.id).paginate(page: params[:page])
    authorize!
  end

  def show
    authorize!
  end

  def new
    @codeharbor_link = CodeharborLink.new
    authorize!
  end

  def edit
    authorize!
  end

  def create
    @codeharbor_link = CodeharborLink.new(codeharbor_link_params)
    @codeharbor_link.user = current_user
    authorize!
    create_and_respond(object: @codeharbor_link)
  end

  def update
    update_and_respond(object: @codeharbor_link, params: codeharbor_link_params)
    authorize!
  end

  def destroy
    destroy_and_respond(object: @codeharbor_link)
  end

  private

  def set_codeharbor_link
    @codeharbor_link = CodeharborLink.find(params[:id])
    @codeharbor_link.user = current_user
    authorize!
  end

  def codeharbor_link_params
    params.require(:codeharbor_link).permit(:push_url, :oauth2token, :client_id, :client_secret)
  end
end
