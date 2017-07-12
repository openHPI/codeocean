class ErrorTemplateAttributesController < ApplicationController
  before_action :set_error_template_attribute, only: [:show, :edit, :update, :destroy]

  def authorize!
    authorize(@error_template_attributes || @error_template_attribute)
  end
  private :authorize!

  # GET /error_template_attributes
  # GET /error_template_attributes.json
  def index
    @error_template_attributes = ErrorTemplateAttribute.all.order('important DESC', :key, :id).paginate(page: params[:page])
    authorize!
  end

  # GET /error_template_attributes/1
  # GET /error_template_attributes/1.json
  def show
    authorize!
  end

  # GET /error_template_attributes/new
  def new
    @error_template_attribute = ErrorTemplateAttribute.new
    authorize!
  end

  # GET /error_template_attributes/1/edit
  def edit
    authorize!
  end

  # POST /error_template_attributes
  # POST /error_template_attributes.json
  def create
    @error_template_attribute = ErrorTemplateAttribute.new(error_template_attribute_params)
    authorize!

    respond_to do |format|
      if @error_template_attribute.save
        format.html { redirect_to @error_template_attribute, notice: 'Error template attribute was successfully created.' }
        format.json { render :show, status: :created, location: @error_template_attribute }
      else
        format.html { render :new }
        format.json { render json: @error_template_attribute.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /error_template_attributes/1
  # PATCH/PUT /error_template_attributes/1.json
  def update
    authorize!
    respond_to do |format|
      if @error_template_attribute.update(error_template_attribute_params)
        format.html { redirect_to @error_template_attribute, notice: 'Error template attribute was successfully updated.' }
        format.json { render :show, status: :ok, location: @error_template_attribute }
      else
        format.html { render :edit }
        format.json { render json: @error_template_attribute.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /error_template_attributes/1
  # DELETE /error_template_attributes/1.json
  def destroy
    authorize!
    @error_template_attribute.destroy
    respond_to do |format|
      format.html { redirect_to error_template_attributes_url, notice: 'Error template attribute was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_error_template_attribute
      @error_template_attribute = ErrorTemplateAttribute.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def error_template_attribute_params
      params[:error_template_attribute].permit(:key, :description, :regex, :important)
    end
end
