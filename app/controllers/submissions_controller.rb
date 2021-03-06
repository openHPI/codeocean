# frozen_string_literal: true

class SubmissionsController < ApplicationController
  include ActionController::Live
  include CommonBehavior
  include Lti
  include SubmissionParameters
  include SubmissionScoring
  include Tubesock::Hijack

  before_action :set_submission,
    only: %i[download download_file render_file run score extract_errors show statistics test]
  before_action :set_docker_client, only: %i[run test]
  before_action :set_files, only: %i[download download_file render_file show run]
  before_action :set_file, only: %i[download_file render_file run]
  before_action :set_mime_type, only: %i[download_file render_file]
  skip_before_action :verify_authenticity_token, only: %i[download_file render_file]

  def max_run_output_buffer_size
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
    if @embed_options[:disable_download]
      raise Pundit::NotAuthorizedError
    end

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
    if @embed_options[:disable_download]
      raise Pundit::NotAuthorizedError
    end

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

  def run
    # TODO: reimplement SSEs with websocket commands
    # with_server_sent_events do |server_sent_event|
    #   output = @docker_client.execute_run_command(@submission, sanitize_filename)

    #   server_sent_event.write({stdout: output[:stdout]}, event: 'output') if output[:stdout]
    #   server_sent_event.write({stderr: output[:stderr]}, event: 'output') if output[:stderr]
    # end

    hijack do |tubesock|
      if @embed_options[:disable_run]
        kill_socket(tubesock)
        return
      end

      # probably add:
      # ensure
      #   #guarantee that the thread is releasing the DB connection after it is done
      #   ApplicationRecord.connectionpool.releaseconnection
      # end
      unless EventMachine.reactor_running? && EventMachine.reactor_thread.alive?
        Thread.new do
          EventMachine.run
        ensure
          ActiveRecord::Base.connection_pool.release_connection
        end
      end

      # socket is the socket into the container, tubesock is the socket to the client

      # give the docker_client the tubesock object, so that it can send messages (timeout)
      @docker_client.tubesock = tubesock

      container_request_time = Time.zone.now
      result = @docker_client.execute_run_command(@submission, sanitize_filename)
      tubesock.send_data JSON.dump({'cmd' => 'status', 'status' => result[:status]})
      @waiting_for_container_time = Time.zone.now - container_request_time

      if result[:status] == :container_running
        socket = result[:socket]
        command = result[:command]

        socket.on :message do |event|
          Rails.logger.info("#{Time.zone.now.getutc}: Docker sending: #{event.data}")
          handle_message(event.data, tubesock, result[:container])
        end

        socket.on :close do |_event|
          kill_socket(tubesock)
        end

        tubesock.onmessage do |data|
          Rails.logger.info("#{Time.zone.now.getutc}: Client sending: #{data}")
          # Check whether the client send a JSON command and kill container
          # if the command is 'client_kill', send it to docker otherwise.
          begin
            parsed = JSON.parse(data) unless data == "\n"
            if parsed.instance_of?(Hash) && parsed['cmd'] == 'client_kill'
              Rails.logger.debug('Client exited container.')
              @docker_client.kill_container(result[:container])
            else
              socket.send data
              Rails.logger.debug { "Sent the received client data to docker:#{data}" }
            end
          rescue JSON::ParserError
            socket.send data
            Rails.logger.debug { "Rescued parsing error, sent the received client data to docker:#{data}" }
            Sentry.set_extras(data: data)
          end
        end

        # Send command after all listeners are attached.
        # Newline required to flush
        @execution_request_time = Time.zone.now
        socket.send "#{command}\n"
        Rails.logger.info("Sent command: #{command}")
      else
        kill_socket(tubesock)
      end
    end
  end

  def kill_socket(tubesock)
    @container_execution_time = Time.zone.now - @execution_request_time if @execution_request_time.present?
    # search for errors and save them as StructuredError (for scoring runs see submission_scoring.rb)
    errors = extract_errors
    send_hints(tubesock, errors)

    # save the output of this "run" as a "testrun" (scoring runs are saved in submission_scoring.rb)
    save_run_output

    # For Python containers, the @run_output is '{"cmd":"exit"}' as a string.
    # If this is the case, we should consider it as blank
    if @run_output.blank? || @run_output&.strip == '{"cmd":"exit"}' || @run_output&.strip == 'timeout:'
      @raw_output ||= ''
      @run_output ||= ''
      parse_message t('exercises.implement.no_output', timestamp: l(Time.zone.now, format: :short)), 'stdout', tubesock
    end

    # Hijacked connection needs to be notified correctly
    tubesock.send_data JSON.dump({'cmd' => 'exit'})
    tubesock.close
  end

  def handle_message(message, tubesock, container)
    @raw_output ||= ''
    @run_output ||= ''
    # Handle special commands first
    case message
      when /^#exit|{"cmd": "exit"}/
        # Just call exit_container on the docker_client.
        # Do not call kill_socket for the websocket to the client here.
        # @docker_client.exit_container closes the socket to the container,
        # kill_socket is called in the "on close handler" of the websocket to the container
        @docker_client.exit_container(container)
      when /^#timeout/
        @run_output = "timeout: #{@run_output}" # add information that this run timed out to the buffer
      else
        # Filter out information about run_command, test_command, user or working directory
        run_command = @submission.execution_environment.run_command % command_substitutions(sanitize_filename)
        test_command = @submission.execution_environment.test_command % command_substitutions(sanitize_filename)
        if test_command.blank?
          # If no test command is set, use the run_command for the RegEx below. Otherwise, no output will be displayed!
          test_command = run_command
        end
        unless %r{root@|:/workspace|#{run_command}|#{test_command}|bash: cmd:canvasevent: command not found}.match?(message)
          parse_message(message, 'stdout', tubesock, container)
        end
    end
  end

  def parse_message(message, output_stream, socket, container = nil, recursive: true)
    parsed = ''
    begin
      parsed = JSON.parse(message)
      if parsed.instance_of?(Hash) && parsed.key?('cmd')
        socket.send_data message
        Rails.logger.info("parse_message sent: #{message}")
        @docker_client.exit_container(container) if container && parsed['cmd'] == 'exit'
      else
        parsed = {'cmd' => 'write', 'stream' => output_stream, 'data' => message}
        socket.send_data JSON.dump(parsed)
        Rails.logger.info("parse_message sent: #{JSON.dump(parsed)}")
      end
    rescue JSON::ParserError
      # Check wether the message contains multiple lines, if true try to parse each line
      if recursive && message.include?("\n")
        message.split("\n").each do |part|
          parse_message(part, output_stream, socket, container, recursive: false)
        end
      elsif message.include?('<img') || message.start_with?('{"cmd') || message.include?('"turtlebatch"')
        # Rails.logger.info('img foung')
        @buffering = true
        @buffer = ''
        @buffer += message
        # Rails.logger.info('Starting to buffer')
      elsif @buffering && message.include?('/>')
        @buffer += message
        parsed = {'cmd' => 'write', 'stream' => output_stream, 'data' => @buffer}
        socket.send_data JSON.dump(parsed)
        # socket.send_data @buffer
        @buffering = false
        # Rails.logger.info('Sent complete buffer')
      elsif @buffering && message.end_with?("}\r")
        @buffer += message
        socket.send_data @buffer
        @buffering = false
        # Rails.logger.info('Sent complete buffer')
      elsif @buffering
        @buffer += message
        # Rails.logger.info('Appending to buffer')
      else
        # Rails.logger.info('else')
        parsed = {'cmd' => 'write', 'stream' => output_stream, 'data' => message}
        socket.send_data JSON.dump(parsed)
        Rails.logger.info("parse_message sent: #{JSON.dump(parsed)}")
      end
    ensure
      @raw_output += parsed['data'].to_s if parsed.instance_of?(Hash) && parsed.key?('data')
      # save the data that was send to the run_output if there is enough space left. this will be persisted as a testrun with cause "run"
      @run_output += JSON.dump(parsed).to_s if @run_output.size <= max_run_output_buffer_size
    end
  end

  def save_run_output
    if @run_output.present?
      @run_output = @run_output[(0..max_run_output_buffer_size - 1)] # trim the string to max_message_buffer_size chars
      Testrun.create(
        file: @file,
        cause: 'run',
        submission: @submission,
        output: @run_output,
        container_execution_time: @container_execution_time,
        waiting_for_container_time: @waiting_for_container_time
      )
    end
  end

  def extract_errors
    results = []
    if @raw_output.present?
      @submission.exercise.execution_environment.error_templates.each do |template|
        pattern = Regexp.new(template.signature).freeze
        if pattern.match(@raw_output)
          results << StructuredError.create_from_template(template, @raw_output, @submission)
        end
      end
    end
    results
  end

  def score
    hijack do |tubesock|
      if @embed_options[:disable_score]
        kill_socket(tubesock)
        return
      end

      unless EventMachine.reactor_running? && EventMachine.reactor_thread.alive?
        Thread.new do
          EventMachine.run
        ensure
          ActiveRecord::Base.connection_pool.release_connection
        end
      end
      # tubesock is the socket to the client

      # the score_submission call will end up calling docker exec, which is blocking.
      # to ensure responsiveness, we therefore open a thread here.
      Thread.new do
        tubesock.send_data JSON.dump(score_submission(@submission))

        # To enable hints when scoring a submission, uncomment the next line:
        # send_hints(tubesock, StructuredError.where(submission: @submission))

        tubesock.send_data JSON.dump({'cmd' => 'exit'})
      ensure
        ActiveRecord::Base.connection_pool.release_connection
      end
    end
  end

  def send_hints(tubesock, errors)
    return if @embed_options[:disable_hints]

    errors = errors.to_a.uniq(&:hint)
    errors.each do |error|
      tubesock.send_data JSON.dump({cmd: 'hint', hint: error.hint, description: error.error_template.description})
    end
  end

  def set_docker_client
    @docker_client = DockerClient.new(execution_environment: @submission.execution_environment)
  end
  private :set_docker_client

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

  def test
    hijack do |tubesock|
      unless EventMachine.reactor_running? && EventMachine.reactor_thread.alive?
        Thread.new do
          EventMachine.run
        ensure
          ActiveRecord::Base.connection_pool.release_connection
        end
      end

      output = @docker_client.execute_test_command(@submission, sanitize_filename)

      # tubesock is the socket to the client
      tubesock.send_data JSON.dump(output)
      tubesock.send_data JSON.dump('cmd' => 'exit')
    end
  end

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
