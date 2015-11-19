class SubmissionsController < ApplicationController
  include ActionController::Live
  include CommonBehavior
  include Lti
  include SubmissionParameters
  include SubmissionScoring
  include Tubesock::Hijack

  before_action :set_submission, only: [:download_file, :render_file, :run, :score, :show, :statistics, :stop, :test]
  before_action :set_docker_client, only: [:run, :test]
  before_action :set_files, only: [:download_file, :render_file, :show]
  before_action :set_file, only: [:download_file, :render_file]
  before_action :set_mime_type, only: [:download_file, :render_file]
  skip_before_action :verify_authenticity_token, only: [:download_file, :render_file]

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

        socket.on :message do |event|
          Rails.logger.info( Time.now.getutc.to_s + ": Docker sending: " + event.data)
          handle_message(event.data, tubesock)
        end

        socket.on :close do |event|
          kill_socket(tubesock)
        end

        tubesock.onmessage do |data|
          Rails.logger.info(Time.now.getutc.to_s + ": Client sending: " + data)
          # Check wether the client send a JSON command and kill container
          # if the command is 'exit', send it to docker otherwise.
          begin
            parsed = JSON.parse(data)
            if parsed['cmd'] == 'exit'
              Rails.logger.debug("Client exited container.")
              @docker_client.exit_container(result[:container])
            else
              socket.send data
              Rails.logger.debug('Sent the received client data to docker:' + data)
            end
          rescue JSON::ParserError
            socket.send data
            Rails.logger.debug('Rescued parsing error, sent the received client data to docker:' + data)
          end
        end
      else
        kill_socket(tubesock)
      end
    end
  end

  def kill_socket(tubesock)
    # Hijacked connection needs to be notified correctly
    tubesock.send_data JSON.dump({'cmd' => 'exit'})
    tubesock.close
  end

  def handle_message(message, tubesock)
    # Handle special commands first
    if (/^exit/.match(message))
      kill_socket(tubesock)
    else
      # Filter out information about run_command, test_command, user or working directory
      run_command = @submission.execution_environment.run_command % command_substitutions(params[:filename])
      test_command = @submission.execution_environment.test_command % command_substitutions(params[:filename])
      if !(/root|workspace|#{run_command}|#{test_command}/.match(message))
        parse_message(message, 'stdout', tubesock)
      end
    end
  end

  def parse_message(message, output_stream, socket, recursive = true)
    begin
      parsed = JSON.parse(message)
      socket.send_data message
      Rails.logger.info('parse_message sent: ' + message)
    rescue JSON::ParserError => e
      # Check wether the message contains multiple lines, if true try to parse each line
      if ((recursive == true) && (message.include? "\n"))
        for part in message.split("\n")
          self.parse_message(part,output_stream,socket,false)
        end
      else
        parsed = {'cmd'=>'write','stream'=>output_stream,'data'=>message}
        socket.send_data JSON.dump(parsed)
        Rails.logger.info('parse_message sent: ' + JSON.dump(parsed))
      end
    end
  end

  def score
    render(json: score_submission(@submission))
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
    Rails.logger.debug('stopping submission ' + @submission)
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
    output = @docker_client.execute_test_command(@submission, params[:filename])
    render(json: [output])
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
end
