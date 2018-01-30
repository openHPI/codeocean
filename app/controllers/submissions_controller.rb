class SubmissionsController < ApplicationController
  include ActionController::Live
  include CommonBehavior
  include Lti
  include SubmissionParameters
  include SubmissionScoring
  include Tubesock::Hijack

  before_action :set_submission, only: [:download, :download_file, :render_file, :run, :score, :extract_errors, :show, :statistics, :stop, :test]
  before_action :set_docker_client, only: [:run, :test]
  before_action :set_files, only: [:download, :download_file, :render_file, :show]
  before_action :set_file, only: [:download_file, :render_file]
  before_action :set_mime_type, only: [:download_file, :render_file]
  skip_before_action :verify_authenticity_token, only: [:download_file, :render_file]

  def max_run_output_buffer_size
    if(@submission.cause == 'requestComments')
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
    {class_name: File.basename(filename, File.extname(filename)).camelize, filename: filename, module_name: File.basename(filename, File.extname(filename)).underscore}
  end
  private :command_substitutions

  def copy_comments
    # copy each annotation and set the target_file.id
    unless(params[:annotations_arr].nil?)
      params[:annotations_arr].each do | annotation |
        #comment = Comment.new(annotation[1].permit(:user_id, :file_id, :user_type, :row, :column, :text, :created_at, :updated_at))
        comment = Comment.new(:user_id => annotation[1][:user_id], :file_id => annotation[1][:file_id], :user_type => current_user.class.name, :row => annotation[1][:row], :column => annotation[1][:column], :text => annotation[1][:text])
        source_file = CodeOcean::File.find(annotation[1][:file_id])

        # retrieve target file
        target_file = @submission.files.detect do |file|
          # file_id has to be that of a the former iteration OR of the initial file (if this is the first run)
          file.file_id == source_file.file_id || file.file_id == source_file.id #seems to be needed here: (check this): || file.file_id == source_file.id ; yes this is needed, for comments on templates as well as comments on files added by users.
        end

        #save to assign an id
        target_file.save!

        comment.file_id = target_file.id
        comment.save!
      end
    end
  end

  def download
    # files = @submission.files.map{ }
    # zipline( files, 'submission.zip')
    # send_data(@file.content, filename: @file.name_with_extension)

    id_file = create_remote_evaluation_mapping

    require 'zip'
    stringio = Zip::OutputStream.write_buffer do |zio|
      @files.each do |file|
        zio.put_next_entry(file.path.to_s == '' ? file.name_with_extension : File.join(file.path, file.name_with_extension))
        zio.write(file.content)
      end

      # zip .co file
      zio.put_next_entry(".co")
      zio.write(File.read id_file)
      File.delete(id_file) if File.exist?(id_file)

      # zip client scripts
      scripts_path = 'app/assets/remote_scripts'
      Dir.foreach(scripts_path) do |file|
        next if file == '.' or file == '..'
        zio.put_next_entry(File.join('.scripts', File.basename(file)))
        zio.write(File.read File.join(scripts_path, file))
      end

    end
    send_data(stringio.string, filename: @submission.exercise.title.tr(" ", "_") + ".zip")
  end

  def download_file
    if @file.native_file?
      send_file(@file.native_file.path)
    else
      send_data(@file.content, filename: @file.name_with_extension)
    end
  end

  def index
    @search = Submission.search(params[:q])
    @submissions = @search.result.includes(:exercise, :user).paginate(page: params[:page])
    authorize!
  end

  def render_file
    if @file.native_file?
      send_file(@file.native_file.path, disposition: 'inline')
    else
      render(text: @file.content)
    end
  end

  def run
    # TODO reimplement SSEs with websocket commands
    # with_server_sent_events do |server_sent_event|
    #   output = @docker_client.execute_run_command(@submission, params[:filename])

    #   server_sent_event.write({stdout: output[:stdout]}, event: 'output') if output[:stdout]
    #   server_sent_event.write({stderr: output[:stderr]}, event: 'output') if output[:stderr]

    #   unless output[:stderr].nil?
    #     if hint = Whistleblower.new(execution_environment: @submission.execution_environment).generate_hint(output[:stderr])
    #       server_sent_event.write(hint, event: 'hint')
    #     else
    #       store_error(output[:stderr])
    #     end
    #   end
    # end

    hijack do |tubesock|
      # probably add:
      # ensure
      #   #guarantee that the thread is releasing the DB connection after it is done
      #   ActiveRecord::Base.connectionpool.releaseconnection
      # end
      Thread.new { EventMachine.run } unless EventMachine.reactor_running? && EventMachine.reactor_thread.alive?


      # socket is the socket into the container, tubesock is the socket to the client

      # give the docker_client the tubesock object, so that it can send messages (timeout)
      @docker_client.tubesock = tubesock

      result = @docker_client.execute_run_command(@submission, params[:filename])
      tubesock.send_data JSON.dump({'cmd' => 'status', 'status' => result[:status]})

      if result[:status] == :container_running
        socket = result[:socket]
        command = result[:command]

        socket.on :message do |event|
          Rails.logger.info( Time.now.getutc.to_s + ": Docker sending: " + event.data)
          handle_message(event.data, tubesock, result[:container])
        end

        socket.on :close do |event|
          kill_socket(tubesock)
        end

        tubesock.onmessage do |data|
          Rails.logger.info(Time.now.getutc.to_s + ": Client sending: " + data)
          # Check whether the client send a JSON command and kill container
          # if the command is 'client_kill', send it to docker otherwise.
          begin
            parsed = JSON.parse(data)
            if parsed['cmd'] == 'client_kill'
              Rails.logger.debug("Client exited container.")
              @docker_client.kill_container(result[:container])
            else
              socket.send data
              Rails.logger.debug('Sent the received client data to docker:' + data)
            end
          rescue JSON::ParserError
            socket.send data
            Rails.logger.debug('Rescued parsing error, sent the received client data to docker:' + data)
          end
        end

        # Send command after all listeners are attached.
        # Newline required to flush
        socket.send command + "\n"
        Rails.logger.info('Sent command: ' + command.to_s)
      else
        kill_socket(tubesock)
      end
    end
  end

  def kill_socket(tubesock)
    # search for errors and save them as StructuredError (for scoring runs see submission_scoring.rb)
    extract_errors

    # save the output of this "run" as a "testrun" (scoring runs are saved in submission_scoring.rb)
    save_run_output

    # Hijacked connection needs to be notified correctly
    tubesock.send_data JSON.dump({'cmd' => 'exit'})
    tubesock.close
  end

  def handle_message(message, tubesock, container)
    @raw_output ||= ''
    @run_output ||= ''
    # Handle special commands first
    if /^#exit/.match(message)
      # Just call exit_container on the docker_client.
      # Do not call kill_socket for the websocket to the client here.
      # @docker_client.exit_container closes the socket to the container,
      # kill_socket is called in the "on close handler" of the websocket to the container
      @docker_client.exit_container(container)
    elsif /^#timeout/.match(message)
      @run_output = 'timeout: ' + @run_output # add information that this run timed out to the buffer
    else
      # Filter out information about run_command, test_command, user or working directory
      run_command = @submission.execution_environment.run_command % command_substitutions(params[:filename])
      test_command = @submission.execution_environment.test_command % command_substitutions(params[:filename])
      unless /root|workspace|#{run_command}|#{test_command}/.match(message)
        parse_message(message, 'stdout', tubesock)
      end
    end
  end

  def parse_message(message, output_stream, socket, recursive = true)
    parsed = ''
    begin
      parsed = JSON.parse(message)
      if parsed.class == Hash and parsed.key?('cmd')
        socket.send_data message
        Rails.logger.info('parse_message sent: ' + message)
      else
        parsed = {'cmd'=>'write','stream'=>output_stream,'data'=>message}
        socket.send_data JSON.dump(parsed)
        Rails.logger.info('parse_message sent: ' + JSON.dump(parsed))
      end
    rescue JSON::ParserError => e
      # Check wether the message contains multiple lines, if true try to parse each line
      if recursive and message.include? "\n"
        for part in message.split("\n")
          self.parse_message(part,output_stream,socket,false)
        end
      elsif message.include? '<img'
        #Rails.logger.info('img foung')
        @buffering = true
        @buffer = ''
        @buffer += message
        #Rails.logger.info('Starting to buffer')
      elsif @buffering and message.include? '/>'
        @buffer += message
        parsed = {'cmd'=>'write','stream'=>output_stream,'data'=>@buffer}
        socket.send_data JSON.dump(parsed)
        #socket.send_data @buffer
        @buffering = false
        #Rails.logger.info('Sent complete buffer')
      elsif @buffering
        @buffer += message
        #Rails.logger.info('Appending to buffer')
      else
        #Rails.logger.info('else')
        parsed = {'cmd'=>'write','stream'=>output_stream,'data'=>message}
        socket.send_data JSON.dump(parsed)
        Rails.logger.info('parse_message sent: ' + JSON.dump(parsed))
      end
    ensure
      @raw_output += parsed['data'] if parsed.class == Hash and parsed.key? 'data'
      # save the data that was send to the run_output if there is enough space left. this will be persisted as a testrun with cause "run"
      @run_output += JSON.dump(parsed) if @run_output.size <= max_run_output_buffer_size
    end
  end

  def save_run_output
    unless @run_output.blank?
      @run_output = @run_output[(0..max_run_output_buffer_size-1)] # trim the string to max_message_buffer_size chars
      Testrun.create(file: @file, cause: 'run', submission: @submission, output: @run_output)
    end
  end

  def extract_errors
    unless @raw_output.blank?
      @submission.exercise.execution_environment.error_templates.each do |template|
        pattern = Regexp.new(template.signature).freeze
        if pattern.match(@raw_output)
          StructuredError.create_from_template(template, @raw_output, @submission)
        end
      end
    end
  end

  def score
    hijack do |tubesock|
      Thread.new { EventMachine.run } unless EventMachine.reactor_running? && EventMachine.reactor_thread.alive?
      # tubesock is the socket to the client

      # the score_submission call will end up calling docker exec, which is blocking.
      # to ensure responsiveness, we therefore open a thread here.
      Thread.new {
        tubesock.send_data JSON.dump(score_submission(@submission))
        tubesock.send_data JSON.dump({'cmd' => 'exit'})
      }
    end
  end

  def set_docker_client
    @docker_client = DockerClient.new(execution_environment: @submission.execution_environment)
  end
  private :set_docker_client

  def set_file
    @file = @files.detect { |file| file.name_with_extension == params[:filename] }
    render(nothing: true, status: 404) unless @file
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

  def show
  end

  def statistics
  end

  def stop
    Rails.logger.debug('stopping submission ' + @submission.id.to_s)
    container = Docker::Container.get(params[:container_id])
    DockerClient.destroy_container(container)
  rescue Docker::Error::NotFoundError
  ensure
    render(nothing: true)
  end

  def store_error(stderr)
    ::Error.create(submission_id: @submission.id, execution_environment_id: @submission.execution_environment.id, message: stderr)
  end
  private :store_error

  def test
    hijack do |tubesock|
      Thread.new { EventMachine.run } unless EventMachine.reactor_running? && EventMachine.reactor_thread.alive?

      output = @docker_client.execute_test_command(@submission, params[:filename])

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
  rescue => exception
    logger.error(exception.message)
    logger.error(exception.backtrace.join("\n"))
    server_sent_event.write({code: 500}, event: 'close')
  ensure
    server_sent_event.close
  end
  private :with_server_sent_events

  def create_remote_evaluation_mapping
    user_id = @submission.user_id
    exercise_id = @submission.exercise_id

    remote_evaluation_mapping = RemoteEvaluationMapping.create(:user_id => user_id, :exercise_id => exercise_id)

    # create .co file
    path = "tmp/" + user_id.to_s + ".co"
    # parse validation token
    content = "#{remote_evaluation_mapping.validation_token}\n"
    # parse remote request url
    content += "#{request.base_url}/evaluate\n"
    @submission.files.each do |file|
      file_path = file.path.to_s == '' ? file.name_with_extension : File.join(file.path, file.name_with_extension)
      content += "#{file_path}=#{file.file_id.to_s}\n"
    end
    File.open(path, "w+") do |f|
      f.write(content)
    end
    path
  end
end
