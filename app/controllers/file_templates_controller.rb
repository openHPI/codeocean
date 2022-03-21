# frozen_string_literal: true

class FileTemplatesController < ApplicationController
  before_action :set_file_template, only: %i[show edit update destroy]

  def authorize!
    authorize(@file_template || @file_templates)
  end
  private :authorize!

  def by_file_type
    @file_templates = FileTemplate.where(file_type_id: params[:file_type_id])
    authorize!
    respond_to do |format|
      format.json { render :show, status: :ok, json: @file_templates.to_json }
    end
  end

  # GET /file_templates
  # GET /file_templates.json
  def index
    @file_templates = FileTemplate.all.order(:file_type_id).paginate(page: params[:page], per_page: per_page_param)
    authorize!
  end

  # GET /file_templates/1
  # GET /file_templates/1.json
  def show
    authorize!
  end

  # GET /file_templates/new
  def new
    @file_template = FileTemplate.new
    authorize!
  end

  # GET /file_templates/1/edit
  def edit
    authorize!
  end

  # POST /file_templates
  # POST /file_templates.json
  def create
    @file_template = FileTemplate.new(file_template_params)
    authorize!

    respond_to do |format|
      if @file_template.save
        format.html { redirect_to @file_template, notice: t('shared.object_created', model: @file_template.class.model_name.human) }
        format.json { render :show, status: :created, location: @file_template }
      else
        format.html { render :new }
        format.json { render json: @file_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /file_templates/1
  # PATCH/PUT /file_templates/1.json
  def update
    authorize!
    respond_to do |format|
      if @file_template.update(file_template_params)
        format.html { redirect_to @file_template, notice: t('shared.object_updated', model: @file_template.class.model_name.human) }
        format.json { render :show, status: :ok, location: @file_template }
      else
        format.html { render :edit }
        format.json { render json: @file_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /file_templates/1
  # DELETE /file_templates/1.json
  def destroy
    authorize!
    @file_template.destroy
    respond_to do |format|
      format.html { redirect_to file_templates_url, notice: t('shared.object_destroyed', model: @file_template.class.model_name.human) }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_file_template
    @file_template = FileTemplate.find(params[:id])
  end

  def file_template_params
    params[:file_template].permit(:name, :file_type_id, :content) if params[:file_template].present?
  end
end
