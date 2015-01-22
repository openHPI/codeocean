module CodeOcean
  class FilesController < ApplicationController
    include FileParameters

    def authorize!
      authorize(@file)
    end
    private :authorize!

    def create
      @file = CodeOcean::File.new(file_params)
      authorize!
      respond_to do |format|
        if @file.save
          format.html { redirect_to(implement_exercise_path(@file.context.exercise, tab: 2), notice: t('shared.object_created', model: File.model_name.human)) }
          format.json { render(:show, location: @file, status: :created) }
        else
          format.html { render(:new) }
          format.json { render(json: @file.errors, status: :unprocessable_entity) }
        end
      end
    end

    def destroy
      @file = CodeOcean::File.find(params[:id])
      authorize!
      @file.destroy
      respond_to do |format|
        format.html { redirect_to(@file.context, notice: t('shared.object_destroyed', model: File.model_name.human)) }
        format.json { head(:no_content) }
      end
    end

    def file_params
      params[:code_ocean_file].permit(file_attributes).merge(context_type: 'Submission', role: 'user_defined_file')
    end
    private :file_params
  end
end
