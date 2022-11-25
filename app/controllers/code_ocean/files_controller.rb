# frozen_string_literal: true

module CodeOcean
  class FilesController < ApplicationController
    include CommonBehavior
    include FileParameters

    # Overwrite the CSP header and some default actions for the :render_protected_upload action
    content_security_policy false, only: :render_protected_upload
    skip_before_action :deny_access_from_render_host, only: :render_protected_upload
    skip_before_action :verify_authenticity_token, only: :render_protected_upload
    before_action :require_user!, except: :render_protected_upload

    # In case the .realpath cannot resolve a file (for example because it is no longer available)
    rescue_from Errno::ENOENT, with: :render_not_found

    def authorize!
      authorize(@file)
    end
    private :authorize!

    def show_protected_upload
      @file = CodeOcean::File.find(params[:id])
      authorize!
      # The `@file.name_with_extension` is assembled based on the user-selected file type, not on the actual file name stored on disk.
      raise Pundit::NotAuthorizedError if @embed_options[:disable_download] || @file.filepath != params[:filename] || @file.native_file.blank?

      real_location = Pathname(@file.native_file.current_path).realpath
      send_file(real_location, type: 'application/octet-stream', filename: @file.name_with_extension, disposition: 'attachment')
    end

    def render_protected_upload
      # Set @current_user with a new *learner* for Pundit checks
      @current_user = ExternalUser.new

      @file = authorize AuthenticatedUrlHelper.retrieve!(CodeOcean::File, request)

      # The `@file.name_with_extension` is assembled based on the user-selected file type, not on the actual file name stored on disk.
      raise Pundit::NotAuthorizedError unless @file.filepath == params[:filename] || @file.native_file.present?

      real_location = Pathname(@file.native_file.current_path).realpath
      send_file(real_location, type: @file.native_file.content_type, filename: @file.name_with_extension)
    end

    def create
      @file = CodeOcean::File.new(file_params)
      if @file.file_template_id
        content = FileTemplate.find(@file.file_template_id).content
        content.sub! '{{file_name}}', @file.name
        @file.content = content
      end
      authorize!
      create_and_respond(object: @file, path: proc { implement_exercise_path(@file.context.exercise) })
    end

    def create_and_respond(options = {})
      @object = options[:object]
      respond_to do |format|
        if @object.save
          yield if block_given?
          path = options[:path].try(:call) || @object
          respond_with_valid_object(format, notice: t('shared.object_created', model: @object.class.model_name.human),
            path:, status: :created)
        else
          filename = "#{@object.path || ''}/#{@object.name || ''}#{@object.file_type.try(:file_extension) || ''}"
          format.html do
            flash[:danger] = t('files.error.filename', name: filename)
            redirect_to(options[:path])
          end
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
      if params[:code_ocean_file].present?
        params[:code_ocean_file].permit(file_attributes).merge(context_type: 'Submission',
          role: 'user_defined_file')
      end
    end
    private :file_params
  end
end
