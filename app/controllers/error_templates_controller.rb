class ErrorTemplatesController < ApplicationController
  before_action :set_error_template, only: [:show, :edit, :update, :destroy, :add_attribute, :remove_attribute]

  def authorize!
    authorize(@error_templates || @error_template)
  end
  private :authorize!

  # GET /error_templates
  # GET /error_templates.json
  def index
    @error_templates = ErrorTemplate.all.order(:execution_environment_id, :name).paginate(page: params[:page])
    authorize!
  end

  # GET /error_templates/1
  # GET /error_templates/1.json
  def show
    authorize!
  end

  # GET /error_templates/new
  def new
    @error_template = ErrorTemplate.new
    authorize!
  end

  # GET /error_templates/1/edit
  def edit
    authorize!
  end

  # POST /error_templates
  # POST /error_templates.json
  def create
    @error_template = ErrorTemplate.new(error_template_params)
    authorize!

    respond_to do |format|
      if @error_template.save
        format.html { redirect_to @error_template, notice: 'Error template was successfully created.' }
        format.json { render :show, status: :created, location: @error_template }
      else
        format.html { render :new }
        format.json { render json: @error_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /error_templates/1
  # PATCH/PUT /error_templates/1.json
  def update
    authorize!
    respond_to do |format|
      if @error_template.update(error_template_params)
        format.html { redirect_to @error_template, notice: 'Error template was successfully updated.' }
        format.json { render :show, status: :ok, location: @error_template }
      else
        format.html { render :edit }
        format.json { render json: @error_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /error_templates/1
  # DELETE /error_templates/1.json
  def destroy
    authorize!
    @error_template.destroy
    respond_to do |format|
      format.html { redirect_to error_templates_url, notice: 'Error template was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def add_attribute
    authorize!
    @error_template.error_template_attributes << ErrorTemplateAttribute.find(params['error_template_attribute_id'])
    respond_to do |format|
      format.html { redirect_to @error_template }
      format.json { head :no_content }
    end
  end

  def remove_attribute
    authorize!
    @error_template.error_template_attributes.delete(ErrorTemplateAttribute.find(params['error_template_attribute_id']))
    respond_to do |format|
      format.html { redirect_to @error_template }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_error_template
      @error_template = ErrorTemplate.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def error_template_params
      params[:error_template].permit(:name, :execution_environment_id, :signature, :description, :hint)
    end
end
