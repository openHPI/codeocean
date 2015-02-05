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
      authorize!
      create_and_respond(object: @file, path: implement_exercise_path(@file.context.exercise, tab: 2))
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
