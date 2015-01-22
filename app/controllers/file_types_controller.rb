class FileTypesController < ApplicationController
  before_action :set_editor_modes, only: [:create, :edit, :new, :update]
  before_action :set_file_type, only: MEMBER_ACTIONS

  def authorize!
    authorize(@file_type || @file_types)
  end
  private :authorize!

  def create
    @file_type = FileType.new(file_type_params)
    authorize!
    respond_to do |format|
      if @file_type.save
        format.html { redirect_to(@file_type, notice: t('shared.object_created', model: FileType.model_name.human)) }
        format.json { render(:show, location: @file_type, status: :created) }
      else
        format.html { render(:new) }
        format.json { render(json: @file_type.errors, status: :unprocessable_entity) }
      end
    end
  end

  def destroy
    @file_type.destroy
    respond_to do |format|
      format.html { redirect_to(file_types_url, notice: t('shared.object_destroyed', model: FileType.model_name.human)) }
      format.json { head(:no_content) }
    end
  end

  def edit
  end

  def file_type_params
    params[:file_type].permit(:binary, :editor_mode, :executable, :file_extension, :name, :indent_size, :renderable).merge(user_id: current_user.id, user_type: current_user.class.name)
  end
  private :file_type_params

  def index
    @file_types = FileType.all.order(:name)
    authorize!
  end

  def new
    @file_type = FileType.new
    authorize!
  end

  def set_editor_modes
    @editor_modes = Dir.glob('vendor/assets/javascripts/ace/mode-*.js').map do |filename|
      name = filename.gsub(/\w+\/|mode-|.js$/, '')
      [name, "ace/mode/#{name}"]
    end
  end
  private :set_editor_modes

  def set_file_type
    @file_type = FileType.find(params[:id])
    authorize!
  end
  private :set_file_type

  def show
  end

  def update
    respond_to do |format|
      if @file_type.update(file_type_params)
        format.html { redirect_to(@file_type, notice: t('shared.object_updated', model: FileType.model_name.human)) }
        format.json { render(:show, location: @file_type, status: :ok) }
      else
        format.html { render(:edit) }
        format.json { render(json: @file_type.errors, status: :unprocessable_entity) }
      end
    end
  end
end
