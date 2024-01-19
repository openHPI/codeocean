# frozen_string_literal: true

class LiveStreamsController < ApplicationController
  # Including ActionController::Live changes all actions in this controller!
  # Therefore, it is extracted into a separate controller
  include ActionController::Live
  before_action :set_content_type_nosniff

  skip_before_action :deny_access_from_render_host, only: :download_submission_file
  skip_before_action :verify_authenticity_token, only: :download_submission_file
  skip_before_action :set_sentry_context, only: :download_submission_file
  before_action :require_user!, except: :download_submission_file

  def download_submission_file
    @submission = AuthenticatedUrlHelper.retrieve!(Submission, request)
    # Set @current_user with the corresponding learner for Pundit checks
    @current_user = @submission.user
    authorize @submission
  rescue Pundit::NotAuthorizedError
    # TODO: Option to disable?
    # Using the submission ID parameter would allow looking up the corresponding exercise ID
    # Therefore, we just redirect to the root_path, but actually expect to redirect back (that should work!)
    skip_authorization
    redirect_back(fallback_location: root_path, allow_other_host: true, alert: t('exercises.download_file_tree.gone'))
  else
    desired_file = params[:filename].to_s
    runner = Runner.for(current_contributor, @submission.exercise.execution_environment)
    fallback_location = implement_exercise_path(@submission.exercise)
    send_runner_file(runner, desired_file, fallback_location)
  end

  def download_arbitrary_file
    @execution_environment = authorize ExecutionEnvironment.find(params[:id])
    desired_file = "/#{params[:filename]}" # The filename given is absolute; this is an admin-only action.
    runner = Runner.for(current_user, @execution_environment)
    fallback_location = shell_execution_environment_path(@execution_environment)
    privileged = params[:sudo] || @execution_environment.privileged_execution?
    send_runner_file(runner, desired_file, fallback_location, privileged:, exclusive: false)
  end

  private

  def send_runner_file(runner, desired_file, redirect_fallback = root_path, privileged: false, exclusive: true)
    filename = File.basename(desired_file)
    send_stream(filename:, type: 'application/octet-stream', disposition: 'attachment') do |stream|
      runner.download_file(desired_file, privileged_execution: privileged, exclusive:) do |chunk, overall_size, _content_type|
        unless response.committed?
          # Disable Rack::ETag, which would otherwise cause the response to be cached
          # See https://github.com/rack/rack/issues/1619#issuecomment-848460528
          response.set_header('Last-Modified', Time.now.httpdate)
          response.set_header('Content-Length', overall_size) if overall_size
          # We set the content type to 'application/octet-stream' in send_stream
          # response.set_header('Content-Type', content_type) if content_type
          # Commit the response headers immediately, as streaming would otherwise remove the Content-Length header
          # This will prevent chunked transfer encoding from being used, which is okay as we know the overall size
          # See https://github.com/rails/rails/issues/18714
          response.commit!
        end

        begin
          stream.write chunk
        rescue ClientDisconnected
          # The client disconnected, so we stop streaming
          break
        end
      end
    rescue Runner::Error
      redirect_back(fallback_location: redirect_fallback, alert: t('exercises.download_file_tree.gone'))
    end
  end
end
