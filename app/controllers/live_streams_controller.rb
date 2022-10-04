# frozen_string_literal: true

class LiveStreamsController < ApplicationController
  # Including ActionController::Live changes all actions in this controller!
  # Therefore, it is extracted into a separate controller
  include ActionController::Live

  def download_submission_file
    begin
      @submission = authorize AuthenticatedUrlHelper.retrieve!(Submission, request, force_render_host: false)
    rescue Pundit::NotAuthorizedError
      # TODO: Option to disable?
      # Using the submission ID parameter would allow looking up the corresponding exercise ID
      # Therefore, we just redirect to the root_path, but actually expect to redirect back (that should work!)
      redirect_back(fallback_location: root_path, alert: t('exercises.download_file_tree.gone'))
    end

    desired_file = params[:filename].to_s
    runner = Runner.for(current_user, @submission.exercise.execution_environment)
    fallback_location = implement_exercise_path(@submission.exercise)
    send_runner_file(runner, desired_file, fallback_location)
  end

  def download_arbitrary_file
    @execution_environment = authorize ExecutionEnvironment.find(params[:id])
    desired_file = params[:filename].to_s
    runner = Runner.for(current_user, @execution_environment)
    fallback_location = shell_execution_environment_path(@execution_environment)
    privileged = params[:sudo] || @execution_environment.privileged_execution?
    send_runner_file(runner, desired_file, fallback_location, privileged: privileged)
  end

  private

  def send_runner_file(runner, desired_file, redirect_fallback = root_path, privileged: false)
    filename = File.basename(desired_file)
    send_stream(filename: filename, disposition: 'attachment') do |stream|
      runner.download_file desired_file, privileged_execution: privileged do |chunk, overall_size, content_type|
        unless response.committed?
          # Disable Rack::ETag, which would otherwise cause the response to be cached
          # See https://github.com/rack/rack/issues/1619#issuecomment-848460528
          response.set_header('Last-Modified', Time.now.httpdate)
          response.set_header('Content-Length', overall_size) if overall_size
          response.set_header('Content-Type', content_type) if content_type
          # Commit the response headers immediately, as streaming would otherwise remove the Content-Length header
          # This will prevent chunked transfer encoding from being used, which is okay as we know the overall size
          # See https://github.com/rails/rails/issues/18714
          response.commit!
        end

        if stream.connected?
          stream.write chunk
        else
          # The client disconnected, so we stop streaming
          break
        end
      end
    rescue Runner::Error
      redirect_back(fallback_location: redirect_fallback, alert: t('exercises.download_file_tree.gone'))
    end
  end

  # TODO: Taken from Rails 7, remove when upgrading
  # rubocop:disable all
  def send_stream(filename:, disposition: "attachment", type: nil)
    response.headers["Content-Type"] =
      (type.is_a?(Symbol) ? Mime[type].to_s : type) ||
        Mime::Type.lookup_by_extension(File.extname(filename).downcase.delete(".")) ||
        "application/octet-stream"

    response.headers["Content-Disposition"] =
      ActionDispatch::Http::ContentDisposition.format(disposition: disposition, filename: filename)

    yield response.stream
  ensure
    response.stream.close
  end
  # rubocop:enable all
end
