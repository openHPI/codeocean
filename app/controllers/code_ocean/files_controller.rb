module CodeOcean
  class FilesController < ApplicationController
    include CommonBehavior
    include FileParameters

    def authorize!
      authorize(@file)
    end
    private :authorize!

    def create
      @file = CodeOcean::File.new(file_params)
      if @file.file_template_id
        content = FileTemplate.find(@file.file_template_id).content
        content.sub! '{{file_name}}', @file.name
        @file.content = content
      end
      authorize!
      create_and_respond(object: @file, path: proc { implement_exercise_path(@file.context.exercise, tab: 2) })
    end

    def create_and_respond(options = {})
      @object = options[:object]
      respond_to do |format|
        if @object.save
          yield if block_given?
          path = options[:path].try(:call) || @object
          respond_with_valid_object(format, notice: t('shared.object_created', model: @object.class.model_name.human), path: path, status: :created)
        else
          filename = (@object.path || '') + '/' + (@object.name || '') + (@object.file_type.try(:file_extension) || '')
          format.html { redirect_to(options[:path]); flash[:danger] = t('files.error.filename', name: filename) }
          format.json { render(json: @object.errors, status: :unprocessable_entity) }
        end
      end
    end

    def destroy
      @file = CodeOcean::File.find(params[:id])
      authorize!
      destroy_and_respond(object: @file, path: @file.context)
    end

    def file_params
      params[:code_ocean_file].permit(file_attributes).merge(context_type: 'Submission', role: 'user_defined_file')
    end
    private :file_params
  end
end
