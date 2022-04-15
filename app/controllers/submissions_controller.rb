# frozen_string_literal: true

class SubmissionsController < ApplicationController
  include ActionController::Live
  include CommonBehavior
  include Lti
  include SubmissionParameters
  include Tubesock::Hijack

  before_action :require_user!
  before_action :set_submission, only: %i[download download_file render_file run score show statistics test]
  before_action :set_files, only: %i[download show]
  before_action :set_files_and_specific_file, only: %i[download_file render_file run test]
  before_action :set_mime_type, only: %i[download_file render_file]
  skip_before_action :verify_authenticity_token, only: %i[download_file render_file]

  def create
    @submission = Submission.new(submission_params)
    authorize!
    create_and_respond(object: @submission)
  end

  def download
    raise Pundit::NotAuthorizedError if @embed_options[:disable_download]

    id_file = create_remote_evaluation_mapping

    stringio = Zip::OutputStream.write_buffer do |zio|
      @files.each do |file|
        zio.put_next_entry(file.filepath)
        zio.write(file.content.presence || file.native_file.read)
      end

      # zip exercise description
      zio.put_next_entry("#{t('activerecord.models.exercise.one')}.txt")
      zio.write("#{@submission.exercise.title}\r\n======================\r\n")
      zio.write(@submission.exercise.description)

      # zip .co file
      zio.put_next_entry('.co')
      zio.write(File.read(id_file))
      File.delete(id_file) if File.exist?(id_file)

      # zip client scripts
      scripts_path = 'app/assets/remote_scripts'
      Dir.foreach(scripts_path) do |file|
        next if (file == '.') || (file == '..')

        zio.put_next_entry(File.join('.scripts', File.basename(file)))
        zio.write(File.read(File.join(scripts_path, file)))
      end
    end
    send_data(stringio.string, filename: "#{@submission.exercise.title.tr(' ', '_')}.zip")
  end

  def download_file
    raise Pundit::NotAuthorizedError if @embed_options[:disable_download]

    if @file.native_file?
      send_file(@file.native_file.path)
    else
      send_data(@file.content, filename: @file.name_with_extension)
    end
  end

  def index
    @search = Submission.ransack(params[:q])
    @submissions = @search.result.includes(:exercise, :user).paginate(page: params[:page], per_page: per_page_param)
    authorize!
  end

  def render_file
    if @file.native_file?
      send_file(@file.native_file.path, disposition: 'inline')
    else
      render(plain: @file.content)
    end
  end

  def run
    # These method-local socket variables are required in order to use one socket
    # in the callbacks of the other socket. As the callbacks for the client socket
    # are registered first, the runner socket may still be nil.
    client_socket, runner_socket = nil

    hijack do |tubesock|
      client_socket = tubesock

      client_socket.onopen do |_event|
        kill_client_socket(client_socket) if @embed_options[:disable_run]
      end

      client_socket.onclose do |_event|
        runner_socket&.close(:terminated_by_client)
      end

      client_socket.onmessage do |raw_event|
        # Obviously, this is just flushing the current connection: Filtering.
        next if raw_event == "\n"

        # Otherwise, we expect to receive a JSON: Parsing.
        event = JSON.parse(raw_event).deep_symbolize_keys

        case event[:cmd].to_sym
          when :client_kill
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
            Sentry.set_extras(event: event)
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

    @output = +''
    durations = @submission.run(@file) do |socket|
      runner_socket = socket
      client_socket.send_data JSON.dump({cmd: :status, status: :container_running})

      runner_socket.on :stdout do |data|
        json_data = prepare data, :stdout
        @output << json_data[0, max_output_buffer_size - @output.size]
        client_socket.send_data(json_data)
      end

      runner_socket.on :stderr do |data|
        json_data = prepare data, :stderr
        @output << json_data[0, max_output_buffer_size - @output.size]
        client_socket.send_data(json_data)
      end

      runner_socket.on :exit do |exit_code|
        exit_statement =
          if @output.empty? && exit_code.zero?
            t('exercises.implement.no_output_exit_successful', timestamp: l(Time.zone.now, format: :short), exit_code: exit_code)
          elsif @output.empty?
            t('exercises.implement.no_output_exit_failure', timestamp: l(Time.zone.now, format: :short), exit_code: exit_code)
          elsif exit_code.zero?
            "\n#{t('exercises.implement.exit_successful', timestamp: l(Time.zone.now, format: :short), exit_code: exit_code)}"
          else
            "\n#{t('exercises.implement.exit_failure', timestamp: l(Time.zone.now, format: :short), exit_code: exit_code)}"
          end
        client_socket.send_data JSON.dump({cmd: :write, stream: :stdout, data: "#{exit_statement}\n"})
        client_socket.send_data JSON.dump({cmd: :out_of_memory}) if exit_code == 137

        close_client_connection(client_socket)
      end
    end
    @container_execution_time = durations[:execution_duration]
    @waiting_for_container_time = durations[:waiting_duration]
  rescue Runner::Error::ExecutionTimeout => e
    client_socket.send_data JSON.dump({cmd: :status, status: :timeout})
    close_client_connection(client_socket)
    Rails.logger.debug { "Running a submission timed out: #{e.message}" }
    @output = "timeout: #{@output}"
    extract_durations(e)
  rescue Runner::Error => e
    client_socket.send_data JSON.dump({cmd: :status, status: :container_depleted})
    close_client_connection(client_socket)
    Rails.logger.debug { "Runner error while running a submission: #{e.message}" }
    extract_durations(e)
  ensure
    save_run_output
  end

  def score
    hijack do |tubesock|
      tubesock.onopen do |_event|
        kill_client_socket(tubesock) if @embed_options[:disable_score]

        tubesock.send_data(JSON.dump(@submission.calculate_score))
        # To enable hints when scoring a submission, uncomment the next line:
        # send_hints(tubesock, StructuredError.where(submission: @submission))
        kill_client_socket(tubesock)
      end
    rescue Runner::Error => e
      tubesock.send_data JSON.dump({cmd: :status, status: :container_depleted})
      kill_client_socket(tubesock)
      Rails.logger.debug { "Runner error while scoring submission #{@submission.id}: #{e.message}" }
    end
  end

  def show; end

  def statistics; end

  def test
    hijack do |tubesock|
      tubesock.onopen do |_event|
        kill_client_socket(tubesock) if @embed_options[:disable_run]

        tubesock.send_data(JSON.dump(@submission.test(@file)))
        kill_client_socket(tubesock)
      end
    rescue Runner::Error => e
      tubesock.send_data JSON.dump({cmd: :status, status: :container_depleted})
      kill_client_socket(tubesock)
      Rails.logger.debug { "Runner error while testing submission #{@submission.id}: #{e.message}" }
    end
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
    client_socket.send_data JSON.dump({cmd: :exit})
    client_socket.close
  end

  def create_remote_evaluation_mapping
    user = @submission.user
    exercise_id = @submission.exercise_id

    remote_evaluation_mapping = RemoteEvaluationMapping.create(
      user: user,
      exercise_id: exercise_id,
      study_group_id: session[:study_group_id]
    )

    # create .co file
    path = "tmp/#{user.id}.co"
    # parse validation token
    content = "#{remote_evaluation_mapping.validation_token}\n"
    # parse remote request url
    content += "#{request.base_url}/evaluate\n"
    @submission.files.each do |file|
      content += "#{file.filepath}=#{file.file_id}\n"
    end
    File.write(path, content)
    path
  end

  def extract_durations(error)
    @container_execution_time = error.execution_duration
    @waiting_for_container_time = error.waiting_duration
  end

  def extract_errors
    results = []
    if @output.present?
      @submission.exercise.execution_environment.error_templates.each do |template|
        pattern = Regexp.new(template.signature).freeze
        results << StructuredError.create_from_template(template, @output, @submission) if pattern.match(@output)
      end
    end
    results
  end

  def max_output_buffer_size
    if @submission.cause == 'requestComments'
      5000
    else
      500
    end
  end

  def prepare(data, stream)
    if valid_command? data
      data
    else
      JSON.dump({cmd: :write, stream: stream, data: data})
    end
  end

  def sanitize_filename
    params[:filename].gsub(/\.json$/, '')
  end

  # save the output of this "run" as a "testrun" (scoring runs are saved in submission.rb)
  def save_run_output
    Testrun.create(
      file: @file,
      cause: 'run',
      submission: @submission,
      output: @output,
      container_execution_time: @container_execution_time,
      waiting_for_container_time: @waiting_for_container_time
    )
  end

  def send_hints(tubesock, errors)
    return if @embed_options[:disable_hints]

    errors = errors.to_a.uniq(&:hint)
    errors.each do |error|
      tubesock.send_data JSON.dump({cmd: 'hint', hint: error.hint, description: error.error_template.description})
    end
  end

  def set_files_and_specific_file
    # @files contains all visible files for the user
    # @file contains the specific file requested for run / test / render / ...
    set_files
    @file = @files.detect {|file| file.filepath == sanitize_filename }
    head :not_found unless @file
  end

  def set_files
    @files = @submission.collect_files.select(&:visible)
  end

  def set_mime_type
    @mime_type = Mime::Type.lookup_by_extension(@file.file_type.file_extension.gsub(/^\./, ''))
    response.headers['Content-Type'] = @mime_type.to_s
  end

  def set_submission
    @submission = Submission.find(params[:id])
    authorize!
  end

  def valid_command?(data)
    parsed = JSON.parse(data)
    parsed.instance_of?(Hash) && parsed.key?('cmd')
  rescue JSON::ParserError
    false
  end
end
