# frozen_string_literal: true

class FileTypesController < ApplicationController
  include CommonBehavior

  before_action :set_file_type, only: MEMBER_ACTIONS

  def authorize!
    authorize(@file_type || @file_types)
  end
  private :authorize!

  def index
    @file_types = FileType.includes(:user).order(:name).paginate(page: params[:page], per_page: per_page_param)
    authorize!
  end

  def show; end

  def new
    @file_type = FileType.new
    authorize!
  end

  def file_type_params
    if params[:file_type].present?
      params[:file_type].permit(:binary, :editor_mode, :executable, :file_extension, :name, :indent_size, :renderable).merge(user: current_user)
    end
  end
  private :file_type_params

  def edit; end

  def create
    @file_type = FileType.new(file_type_params)
    authorize!
    create_and_respond(object: @file_type)
  end

  def set_file_type
    @file_type = FileType.find(params[:id])
    authorize!
  end
  private :set_file_type

  def update
    update_and_respond(object: @file_type, params: file_type_params)
  end

  def destroy
    destroy_and_respond(object: @file_type)
  end
end
