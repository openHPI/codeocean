# frozen_string_literal: true

class SubmissionsController < ApplicationController
  include ActionController::Live
  include CommonBehavior
  include Lti
  include SubmissionParameters
  include Tubesock::Hijack

  before_action :set_submission,
    only: %i[download download_file render_file run score extract_errors show statistics]
  before_action :set_files, only: %i[download download_file render_file show run]
  before_action :set_file, only: %i[download_file render_file run]
  before_action :set_mime_type, only: %i[download_file render_file]
  skip_before_action :verify_authenticity_token, only: %i[download_file render_file]

  def max_output_buffer_size
    if @submission.cause == 'requestComments'
      5000
    else
      500
    end
  end

  def authorize!
    authorize(@submission || @submissions)
  end
  private :authorize!

  def create
    @submission = Submission.new(submission_params)
    authorize!
    copy_comments
    create_and_respond(object: @submission)
  end

  def command_substitutions(filename)
    {
      class_name: File.basename(filename, File.extname(filename)).upcase_first,
      filename: filename,
      module_name: File.basename(filename, File.extname(filename)).underscore,
    }
  end
  private :command_substitutions

  def copy_comments
    # copy each annotation and set the target_file.id
    params[:annotations_arr]&.each do |annotation|
      # comment = Comment.new(annotation[1].permit(:user_id, :file_id, :user_type, :row, :column, :text, :created_at, :updated_at))
      comment = Comment.new(user_id: annotation[1][:user_id], file_id: annotation[1][:file_id],
        user_type: current_user.class.name, row: annotation[1][:row], column: annotation[1][:column], text: annotation[1][:text])
      source_file = CodeOcean::File.find(annotation[1][:file_id])

      # retrieve target file
      target_file = @submission.files.detect do |file|
        # file_id has to be that of a the former iteration OR of the initial file (if this is the first run)
        file.file_id == source_file.file_id || file.file_id == source_file.id # seems to be needed here: (check this): || file.file_id == source_file.id ; yes this is needed, for comments on templates as well as comments on files added by users.
      end

      # save to assign an id
      target_file.save!

      comment.file_id = target_file.id
      comment.save!
    end
  end

  def download
    raise Pundit::NotAuthorizedError if @embed_options[:disable_download]

    # files = @submission.files.map{ }
    # zipline( files, 'submission.zip')
    # send_data(@file.content, filename: @file.name_with_extension)

    id_file = create_remote_evaluation_mapping

    stringio = Zip::OutputStream.write_buffer do |zio|
      @files.each do |file|
        zio.put_next_entry(if file.path.to_s == ''
                             file.name_with_extension
                           else
                             File.join(file.path,
                               file.name_with_extension)
                           end)
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
    @submissions = @search.result.includes(:exercise, :user).paginate(page: params[:page])
    authorize!
  end

  def render_file
    if @file.native_file?
      send_file(@file.native_file.path, disposition: 'inline')
    else
      render(plain: @file.content)
    end
  end

  def handle_websockets(tubesock, socket)
    tubesock.send_data JSON.dump({cmd: :status, status: :container_running})
    @output = +''

    socket.on :output do |data|
      Rails.logger.info("#{Time.zone.now.getutc}: Container sending: #{data}")
      @output << data if @output.size + data.size <= max_output_buffer_size
    end

    socket.on :stdout do |data|
      tubesock.send_data(JSON.dump({cmd: :write, stream: :stdout, data: data}))
    end

    socket.on :stderr do |data|
      tubesock.send_data(JSON.dump({cmd: :write, stream: :stderr, data: data}))
    end

    socket.on :exit do |exit_code|
      EventMachine.stop_event_loop
      if @output.empty?
        tubesock.send_data JSON.dump({cmd: :write, stream: :stdout, data: "#{t('exercises.implement.no_output', timestamp: l(Time.zone.now, format: :short))}\n"})
      end
      tubesock.send_data JSON.dump({cmd: :write, stream: :stdout, data: "#{t('exercises.implement.exit', exit_code: exit_code)}\n"})
      kill_socket(tubesock)
    end

    tubesock.onmessage do |event|
      event = JSON.parse(event).deep_symbolize_keys
      case event[:cmd].to_sym
        when :client_kill
          EventMachine.stop_event_loop
          kill_socket(tubesock)
          Rails.logger.debug('Client exited container.')
        when :result
          socket.send event[:data]
        else
          Rails.logger.info("Unknown command from client: #{event[:cmd]}")
      end

    rescue JSON::ParserError
      Rails.logger.debug { "Data received from client is not valid json: #{data}" }
      Sentry.set_extras(data: data)
    rescue TypeError
      Rails.logger.debug { "JSON data received from client cannot be parsed to hash: #{data}" }
      Sentry.set_extras(data: data)
    end
  end

  def run
    hijack do |tubesock|
      return kill_socket(tubesock) if @embed_options[:disable_run]

      durations = @submission.run(sanitize_filename) do |socket|
        handle_websockets(tubesock, socket)
      end
      @container_execution_time = durations[:execution_duration]
      @waiting_for_container_time = durations[:waiting_duration]
      save_run_output
    rescue Runner::Error::ExecutionTimeout => e
      tubesock.send_data JSON.dump({cmd: :status, status: :timeout})
      kill_socket(tubesock)
      Rails.logger.debug { "Running a submission timed out: #{e.message}" }
    rescue Runner::Error => e
      tubesock.send_data JSON.dump({cmd: :status, status: :container_depleted})
      kill_socket(tubesock)
      Rails.logger.debug { "Runner error while running a submission: #{e.message}" }
    end
  end

  def kill_socket(tubesock)
    # search for errors and save them as StructuredError (for scoring runs see submission_scoring.rb)
    errors = extract_errors
    send_hints(tubesock, errors)

    # Hijacked connection needs to be notified correctly
    tubesock.send_data JSON.dump({cmd: :exit})
    tubesock.close
  end

  # save the output of this "run" as a "testrun" (scoring runs are saved in submission_scoring.rb)
  def save_run_output
    return if @output.blank?

    @output = @output[0, max_output_buffer_size] # trim the string to max_output_buffer_size chars
    Testrun.create(
      file: @file,
      cause: 'run',
      submission: @submission,
      output: @output,
      container_execution_time: @container_execution_time,
      waiting_for_container_time: @waiting_for_container_time
    )
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

  def score
    hijack do |tubesock|
      return kill_socket(tubesock) if @embed_options[:disable_run]

      tubesock.send_data(@submission.calculate_score)
      # To enable hints when scoring a submission, uncomment the next line:
      # send_hints(tubesock, StructuredError.where(submission: @submission))
    rescue Runner::Error::ExecutionTimeout => e
      tubesock.send_data JSON.dump({cmd: :status, status: :timeout})
      Rails.logger.debug { "Scoring a submission timed out: #{e.message}" }
    rescue Runner::Error => e
      tubesock.send_data JSON.dump({cmd: :status, status: :container_depleted})
      Rails.logger.debug { "Runner error while scoring a submission: #{e.message}" }
    ensure
      tubesock.send_data JSON.dump({cmd: :exit})
      tubesock.close
    end
  end

  def send_hints(tubesock, errors)
    return if @embed_options[:disable_hints]

    errors = errors.to_a.uniq(&:hint)
    errors.each do |error|
      tubesock.send_data JSON.dump({cmd: 'hint', hint: error.hint, description: error.error_template.description})
    end
  end

  # def set_docker_client
  #  @docker_client = DockerClient.new(execution_environment: @submission.execution_environment)
  # end
  # private :set_docker_client

  def set_file
    @file = @files.detect {|file| file.name_with_extension == sanitize_filename }
    head :not_found unless @file
  end
  private :set_file

  def set_files
    @files = @submission.collect_files.select(&:visible)
  end
  private :set_files

  def set_mime_type
    @mime_type = Mime::Type.lookup_by_extension(@file.file_type.file_extension.gsub(/^\./, ''))
    response.headers['Content-Type'] = @mime_type.to_s
  end
  private :set_mime_type

  def set_submission
    @submission = Submission.find(params[:id])
    authorize!
  end
  private :set_submission

  def show; end

  def statistics; end

  # TODO: make this run, but with the test command
  # def test
  #   hijack do |tubesock|
  #     unless EventMachine.reactor_running? && EventMachine.reactor_thread.alive?
  #       Thread.new do
  #         EventMachine.run
  #       ensure
  #         ActiveRecord::Base.connection_pool.release_connection
  #       end
  #     end
  #     output = @docker_client.execute_test_command(@submission, sanitize_filename)
  #     # tubesock is the socket to the client
  #     tubesock.send_data JSON.dump(output)
  #     tubesock.send_data JSON.dump('cmd' => 'exit')
  #   end
  # end

  def with_server_sent_events
    response.headers['Content-Type'] = 'text/event-stream'
    server_sent_event = SSE.new(response.stream)
    server_sent_event.write(nil, event: 'start')
    yield(server_sent_event) if block_given?
    server_sent_event.write({code: 200}, event: 'close')
  rescue StandardError => e
    Sentry.capture_exception(e)
    logger.error(e.message)
    logger.error(e.backtrace.join("\n"))
    server_sent_event.write({code: 500}, event: 'close')
  ensure
    server_sent_event.close
  end
  private :with_server_sent_events

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
      file_path = file.path.to_s == '' ? file.name_with_extension : File.join(file.path, file.name_with_extension)
      content += "#{file_path}=#{file.file_id}\n"
    end
    File.open(path, 'w+') do |f|
      f.write(content)
    end
    path
  end

  def sanitize_filename
    params[:filename].gsub(/\.json$/, '')
  end
end
