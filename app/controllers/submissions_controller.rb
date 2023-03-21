# frozen_string_literal: true

class SubmissionsController < ApplicationController
  include CommonBehavior
  include Lti
  include FileConversion
  include SubmissionParameters
  include Tubesock::Hijack

  before_action :set_submission, only: %i[download download_file run score show statistics test]
  before_action :set_testrun, only: %i[run score test]
  before_action :set_files, only: %i[download show]
  before_action :set_files_and_specific_file, only: %i[download_file run test]
  before_action :set_content_type_nosniff, only: %i[download download_file render_file]

  # Overwrite the CSP header and some default actions for the :render_file action
  content_security_policy false, only: :render_file
  skip_before_action :deny_access_from_render_host, only: :render_file
  before_action :require_user!, except: :render_file
  # We want to serve .js files without raising a `ActionController::InvalidCrossOriginRequest` exception
  skip_before_action :verify_authenticity_token, only: %i[render_file download_file]

  def index
    @search = Submission.ransack(params[:q])
    @submissions = @search.result.includes(:exercise, :user).paginate(page: params[:page], per_page: per_page_param)
    authorize!
  end

  def download
    raise Pundit::NotAuthorizedError if @embed_options[:disable_download]

    id_file = create_remote_evaluation_mapping

    stringio = Zip::OutputStream.write_buffer do |zio|
      @files.each do |file|
        zio.put_next_entry(file.filepath.delete_prefix('/'))
        zio.write(file.read)
      end

      # zip exercise description
      zio.put_next_entry("#{t('activerecord.models.exercise.one')}.txt")
      zio.write("#{@submission.exercise.title}\r\n======================\r\n")
      zio.write(@submission.exercise.description)

      # zip .co file
      zio.put_next_entry('.co')
      zio.write(File.read(id_file))
      FileUtils.rm_rf(id_file)

      # zip client scripts
      scripts_path = 'app/assets/remote_scripts'
      Dir.foreach(scripts_path) do |file|
        next if (file == '.') || (file == '..')

        zio.put_next_entry(File.join('.scripts', File.basename(file)))
        zio.write(File.read(File.join(scripts_path, file)))
      end
    end
    zip_data = stringio.string
    response.set_header('Content-Length', zip_data.size)
    send_data(zip_data, type: 'application/octet-stream', filename: "#{@submission.exercise.title.tr(' ', '_')}.zip", disposition: 'attachment')
  end

  def download_file
    raise Pundit::NotAuthorizedError if @embed_options[:disable_download]

    if @file.native_file?
      redirect_to protected_upload_path(id: @file.id, filename: @file.filepath)
    else
      response.set_header('Content-Length', @file.size)
      send_data(@file.content, type: 'application/octet-stream', filename: @file.name_with_extension, disposition: 'attachment')
    end
  end

  def show; end

  def render_file
    # Set @current_user with a new *learner* for Pundit checks
    @current_user = ExternalUser.new

    @submission = authorize AuthenticatedUrlHelper.retrieve!(Submission, request, cookies)

    # Throws an exception if the file is not found
    set_files_and_specific_file

    # Allows access to other files of the same submission, e.g., a linked JS or CSS file where we cannot expect a token in the URL
    cookie_name = AuthenticatedUrlHelper.cookie_name_for(:render_file_token)
    if params[AuthenticatedUrlHelper.query_parameter].present?
      cookies[cookie_name] = AuthenticatedUrlHelper.prepare_short_living_cookie(request.url)
    end

    # Finally grant access and send the file
    if @file.native_file?
      url = render_protected_upload_url(id: @file.id, filename: @file.filepath)
      redirect_to AuthenticatedUrlHelper.sign(url, @file)
    else
      response.set_header('Content-Length', @file.size)
      send_data(@file.content, filename: @file.name_with_extension, disposition: 'inline')
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def run
    # These method-local socket variables are required in order to use one socket
    # in the callbacks of the other socket. As the callbacks for the client socket
    # are registered first, the runner socket may still be nil.
    client_socket, runner_socket = nil

    hijack do |tubesock|
      client_socket = tubesock

      client_socket.onopen do |_event|
        kill_client_socket(client_socket) and return true if @embed_options[:disable_run]
      end

      client_socket.onclose do |_event|
        runner_socket&.close(:terminated_by_client)
        @testrun[:status] ||= :terminated_by_client
      end

      client_socket.onmessage do |raw_event|
        # Obviously, this is just flushing the current connection: Filtering.
        next if raw_event == "\n"

        # Otherwise, we expect to receive a JSON: Parsing.
        event = JSON.parse(raw_event).deep_symbolize_keys
        event[:cmd] = event[:cmd].to_sym
        event[:stream] = event[:stream].to_sym if event.key? :stream

        # We could store the received event. However, it is also echoed by the container
        # and correctly identified as the original input. Therefore, we don't store
        # it here to prevent duplicated events.
        # @testrun[:messages].push(event)

        case event[:cmd]
          when :client_kill
            @testrun[:status] = :terminated_by_client
            close_client_connection(client_socket)
            Rails.logger.debug('Client exited container.')
          when :result, :canvasevent, :exception
            # The client cannot send something before the runner connection is established.
            if runner_socket.present?
              runner_socket.send_data raw_event
            else
              Rails.logger.info("Could not forward data from client because runner connection was not established yet: #{event[:data].inspect}")
            end
          else
            Rails.logger.info("Unknown command from client: #{event[:cmd]}")
            Sentry.set_extras(event:)
            Sentry.capture_message("Unknown command from client: #{event[:cmd]}")
        end
      rescue JSON::ParserError => e
        Rails.logger.info("Data received from client is not valid json: #{raw_event.inspect}")
        Sentry.set_extras(data: raw_event)
        Sentry.capture_exception(e)
      rescue TypeError => e
        Rails.logger.info("JSON data received from client cannot be parsed as hash: #{raw_event.inspect}")
        Sentry.set_extras(data: raw_event)
        Sentry.capture_exception(e)
      end
    end

    # If running is not allowed (and the socket is closed), we can stop here.
    return true if @embed_options[:disable_run]

    @testrun[:output] = +''
    durations = @submission.run(@file) do |socket, starting_time|
      runner_socket = socket
      @testrun[:starting_time] = starting_time
      client_socket.send_data JSON.dump({cmd: :status, status: :container_running})

      runner_socket.on :stdout do |data|
        message = retrieve_message_from_output data, :stdout
        @testrun[:output] << message[:data].to_s[0, max_output_buffer_size - @testrun[:output].size] if message[:data]
        send_and_store client_socket, message
      end

      runner_socket.on :stderr do |data|
        message = retrieve_message_from_output data, :stderr
        @testrun[:output] << message[:data].to_s[0, max_output_buffer_size - @testrun[:output].size] if message[:data]
        send_and_store client_socket, message
      end

      runner_socket.on :exit do |exit_code|
        @testrun[:exit_code] = exit_code
        exit_statement =
          if @testrun[:output].empty? && exit_code.zero?
            @testrun[:status] = :ok
            t('exercises.implement.no_output_exit_successful', timestamp: l(Time.zone.now, format: :short), exit_code:)
          elsif @testrun[:output].empty?
            @testrun[:status] = :failed
            t('exercises.implement.no_output_exit_failure', timestamp: l(Time.zone.now, format: :short), exit_code:)
          elsif exit_code.zero?
            @testrun[:status] = :ok
            "\n#{t('exercises.implement.exit_successful', timestamp: l(Time.zone.now, format: :short), exit_code:)}"
          else
            @testrun[:status] = :failed
            "\n#{t('exercises.implement.exit_failure', timestamp: l(Time.zone.now, format: :short), exit_code:)}"
          end
        stream = @testrun[:status] == :ok ? :stdout : :stderr
        send_and_store client_socket, {cmd: :write, stream:, data: "#{exit_statement}\n"}
        if exit_code == 137
          send_and_store client_socket, {cmd: :status, status: :out_of_memory}
          @testrun[:status] = :out_of_memory
        end

        # The client connection will be closed once the file listing finished.
      end

      runner_socket.on :files do |files|
        downloadable_files, = convert_files_json_to_files files
        if downloadable_files.present?
          js_tree = FileTree.new(downloadable_files).to_js_tree
          send_and_store client_socket, {cmd: :files, data: js_tree}
        end

        close_client_connection(client_socket)
      end
    end
    @testrun[:container_execution_time] = durations[:execution_duration]
    @testrun[:waiting_for_container_time] = durations[:waiting_duration]
  rescue Runner::Error::ExecutionTimeout => e
    send_and_store client_socket, {cmd: :status, status: :timeout}
    close_client_connection(client_socket)
    Rails.logger.debug { "Running a submission timed out: #{e.message}" }
    @testrun[:status] ||= :timeout
    @testrun[:output] = "timeout: #{@testrun[:output]}"
    extract_durations(e)
  rescue Runner::Error => e
    # Regardless of the specific error cause, we send a `container_depleted` status to the client.
    send_and_store client_socket, {cmd: :status, status: :container_depleted}
    close_client_connection(client_socket)
    @testrun[:status] ||= :container_depleted
    Rails.logger.debug { "Runner error while running a submission: #{e.message}" }
    extract_durations(e)
  ensure
    save_testrun_output 'run'
  end
  # rubocop:enable Metrics/CyclomaticComplexity:

  def score
    client_socket = nil
    disable_scoring = @embed_options[:disable_score] || !@submission.exercise.teacher_defined_assessment?

    hijack do |tubesock|
      client_socket = tubesock
      tubesock.onopen do |_event|
        kill_client_socket(tubesock) and return true if disable_scoring
      end
    end

    # If scoring is not allowed (and the socket is closed), we can stop here.
    return true if disable_scoring

    # The score is stored separately, we can forward it to the client immediately
    client_socket&.send_data(JSON.dump(@submission.calculate_score))
    # To enable hints when scoring a submission, uncomment the next line:
    # send_hints(client_socket, StructuredError.where(submission: @submission))
    kill_client_socket(client_socket)
  rescue Runner::Error => e
    extract_durations(e)
    send_and_store client_socket, {cmd: :status, status: :container_depleted}
    kill_client_socket(client_socket)
    Rails.logger.debug { "Runner error while scoring submission #{@submission.id}: #{e.message}" }
    @testrun[:passed] = false
  ensure
    save_testrun_output 'assess'
  end

  def create
    @submission = Submission.new(submission_params)
    authorize!
    create_and_respond(object: @submission)
  end

  def statistics; end

  def test
    client_socket = nil

    hijack do |tubesock|
      client_socket = tubesock
      tubesock.onopen do |_event|
        kill_client_socket(tubesock) and return true if @embed_options[:disable_run]
      end
    end

    # If running is not allowed (and the socket is closed), we can stop here.
    return true if @embed_options[:disable_run]

    # The score is stored separately, we can forward it to the client immediately
    client_socket&.send_data(JSON.dump(@submission.test(@file)))
    kill_client_socket(client_socket)
  rescue Runner::Error => e
    extract_durations(e)
    send_and_store client_socket, {cmd: :status, status: :container_depleted}
    kill_client_socket(client_socket)
    Rails.logger.debug { "Runner error while testing submission #{@submission.id}: #{e.message}" }
    @testrun[:passed] = false
  ensure
    save_testrun_output 'assess'
  end

  private

  def authorize!
    authorize(@submission || @submissions)
  end

  def close_client_connection(client_socket)
    # search for errors and save them as StructuredError (for scoring runs see submission.rb)
    errors = extract_errors
    send_hints(client_socket, errors)
    kill_client_socket(client_socket)
  end

  def kill_client_socket(client_socket)
    # We don't want to store this (arbitrary) exit command and redirect it ourselves
    client_socket.send_data JSON.dump({cmd: :exit})
    client_socket.send_data nil, :close
    client_socket.close
  end

  def create_remote_evaluation_mapping
    user = @submission.user
    exercise_id = @submission.exercise_id

    remote_evaluation_mapping = RemoteEvaluationMapping.create(
      user:,
      exercise_id:,
      study_group_id: session[:study_group_id]
    )

    # create .co file
    path = "tmp/#{user.id}.co"
    # parse validation token
    content = "#{remote_evaluation_mapping.validation_token}\n"
    # parse remote request url
    content += "#{evaluate_url}\n"
    @submission.files.each do |file|
      content += "#{file.filepath}=#{file.file_id}\n"
    end
    File.write(path, content)
    path
  end

  def extract_durations(error)
    @testrun[:starting_time] = error.starting_time
    @testrun[:container_execution_time] = error.execution_duration
    @testrun[:waiting_for_container_time] = error.waiting_duration
  end

  def extract_errors
    results = []
    if @testrun[:output].present?
      # First, we test all error templates for a match.
      matching_error_templates = @submission.exercise.execution_environment.error_templates.select do |template|
        pattern = Regexp.new(template.signature).freeze
        pattern.match(@testrun[:output])
      end
      # Second, if there is a match, we preload all ErrorTemplateAttributes and create a StructuredError
      #
      # Reloading the ErrorTemplate is necessary to allow preloading the ErrorTemplateAttributes.
      # However, this results in less (and faster) SQL queries than performing manual lookups.
      ErrorTemplate.where(id: matching_error_templates).joins(:error_template_attributes).includes(:error_template_attributes).each do |template|
        results << StructuredError.create_from_template(template, @testrun[:output], @submission)
      end
    end
    results
  end

  def send_and_store(client_socket, message)
    message[:timestamp] = if @testrun[:starting_time]
                            ActiveSupport::Duration.build(Time.zone.now - @testrun[:starting_time])
                          else
                            0.seconds
                          end
    @testrun[:messages].push message
    @testrun[:status] = message[:status] if message[:status]
    client_socket.send_data JSON.dump(message)
  end

  def max_output_buffer_size
    if @submission.cause == 'requestComments'
      5000
    else
      500
    end
  end

  def sanitize_filename
    params[:filename].gsub(/\.json$/, '')
  end

  # save the output of this "run" as a "testrun" (scoring runs are saved in submission.rb)
  def save_testrun_output(cause)
    testrun = Testrun.create!(
      file: @file,
      passed: @testrun[:passed],
      cause:,
      submission: @submission,
      exit_code: @testrun[:exit_code], # might be nil, e.g., when the run did not finish
      status: @testrun[:status] || :failed,
      output: @testrun[:output].presence, # TODO: Remove duplicated saving of the output after creating TestrunMessages
      container_execution_time: @testrun[:container_execution_time],
      waiting_for_container_time: @testrun[:waiting_for_container_time]
    )
    TestrunMessage.create_for(testrun, @testrun[:messages])
    TestrunExecutionEnvironment.create(testrun:, execution_environment: @submission.used_execution_environment)
  end

  def send_hints(tubesock, errors)
    return if @embed_options[:disable_hints]

    errors = errors.to_a.uniq(&:hint)
    errors.each do |error|
      send_and_store tubesock, {cmd: :hint, hint: error.hint, description: error.error_template.description}
    end
  end

  def set_files_and_specific_file
    # @files contains all visible files for the user
    # @file contains the specific file requested for run / test / render / ...
    set_files
    @file = @files.detect {|file| file.filepath == sanitize_filename }
    raise ActiveRecord::RecordNotFound unless @file
  end

  def set_files
    @files = @submission.collect_files.select(&:visible)
  end

  def set_content_type_nosniff
    # When sending a file, we want to ensure that browsers follow our Content-Type header
    response.headers['X-Content-Type-Options'] = 'nosniff'
  end

  def set_submission
    @submission = Submission.find(params[:id])
    authorize!
  end

  def set_testrun
    @testrun = {
      messages: [],
      exit_code: nil,
      status: nil,
    }
  end

  def retrieve_message_from_output(data, stream)
    parsed = JSON.parse(data)
    if parsed.instance_of?(Hash) && parsed.key?('cmd')
      parsed.symbolize_keys!
      # Symbolize two values if present
      parsed[:cmd] = parsed[:cmd].to_sym
      parsed[:stream] = parsed[:stream].to_sym if parsed.key? :stream
      parsed
    else
      {cmd: :write, stream:, data:}
    end
  rescue JSON::ParserError
    {cmd: :write, stream:, data:}
  end

  def augment_files_for_download(files)
    submission_files = @submission.collect_files + @submission.exercise.files
    files.filter_map do |file|
      # Reject files that were already present in the submission
      # We further reject files that share the same name (excl. file extension) and path as a file in the submission
      # This is, for example, used to filter compiled .class files in Java submissions
      next if submission_files.any? {|submission_file| submission_file.filepath_without_extension == file.filepath_without_extension }

      # Downloadable files get a signed download_path and an indicator whether we performed a privileged execution
      file.download_path = AuthenticatedUrlHelper.sign(download_stream_file_submission_url(@submission, file.filepath), @submission)
      file.privileged_execution = @submission.execution_environment.privileged_execution
      file
    end
  end
end
