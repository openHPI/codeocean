class CodeHarborLinksController < ApplicationController
  before_action :set_code_harbor_link, only: [:show, :edit, :update, :destroy]

  # GET /code_harbor_links
  # GET /code_harbor_links.json
  def index
    @code_harbor_links = CodeHarborLink.all
  end

  # GET /code_harbor_links/1
  # GET /code_harbor_links/1.json
  def show
  end

  # GET /code_harbor_links/new
  def new
    @code_harbor_link = CodeHarborLink.new
  end

  # GET /code_harbor_links/1/edit
  def edit
  end

  # POST /code_harbor_links
  # POST /code_harbor_links.json
  def create
    @code_harbor_link = CodeHarborLink.new(code_harbor_link_params)

    respond_to do |format|
      if @code_harbor_link.save
        format.html { redirect_to @code_harbor_link, notice: 'Code harbor link was successfully created.' }
        format.json { render :show, status: :created, location: @code_harbor_link }
      else
        format.html { render :new }
        format.json { render json: @code_harbor_link.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /code_harbor_links/1
  # PATCH/PUT /code_harbor_links/1.json
  def update
    respond_to do |format|
      if @code_harbor_link.update(code_harbor_link_params)
        format.html { redirect_to @code_harbor_link, notice: 'Code harbor link was successfully updated.' }
        format.json { render :show, status: :ok, location: @code_harbor_link }
      else
        format.html { render :edit }
        format.json { render json: @code_harbor_link.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /code_harbor_links/1
  # DELETE /code_harbor_links/1.json
  def destroy
    @code_harbor_link.destroy
    respond_to do |format|
      format.html { redirect_to code_harbor_links_url, notice: 'Code harbor link was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_code_harbor_link
      @code_harbor_link = CodeHarborLink.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def code_harbor_link_params
      params.require(:code_harbor_link).permit(:oauth2token)
    end
end
