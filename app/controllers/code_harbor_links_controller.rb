class CodeHarborLinksController < ApplicationController
  include CommonBehavior
  before_action :set_code_harbor_link, only: [:show, :edit, :update, :destroy]

  def authorize!
    authorize(@code_harbor_link || @code_harbor_links)
  end
  private :authorize!

  # GET /code_harbor_links
  # GET /code_harbor_links.json
  def index
    @code_harbor_links = CodeHarborLink.where(user_id: current_user.id).paginate(page: params[:page])
    authorize!
  end

  # GET /code_harbor_links/1
  # GET /code_harbor_links/1.json
  def show
    authorize!
  end

  # GET /code_harbor_links/new
  def new
    @code_harbor_link = CodeHarborLink.new
    authorize!
  end

  # GET /code_harbor_links/1/edit
  def edit
    authorize!
  end

  # POST /code_harbor_links
  # POST /code_harbor_links.json
  def create
    @code_harbor_link = CodeHarborLink.new(code_harbor_link_params)
    @code_harbor_link.user = current_user
    authorize!
    create_and_respond(object: @code_harbor_link)
  end

  # PATCH/PUT /code_harbor_links/1
  # PATCH/PUT /code_harbor_links/1.json
  def update
    update_and_respond(object: @code_harbor_link, params: code_harbor_link_params)
    authorize!
  end

  # DELETE /code_harbor_links/1
  # DELETE /code_harbor_links/1.json
  def destroy
    destroy_and_respond(object: @code_harbor_link)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_code_harbor_link
      @code_harbor_link = CodeHarborLink.find(params[:id])
      @code_harbor_link.user = current_user
      authorize!
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def code_harbor_link_params
      params.require(:code_harbor_link).permit(:push_url, :oauth2token)
    end
end
