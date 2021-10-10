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

  def run
    # These method-local socket variables are required in order to use one socket
    # in the callbacks of the other socket. As the callbacks for the client socket
    # are registered first, the runner socket may still be nil.
    client_socket, runner_socket = nil

    hijack do |tubesock|
      client_socket = tubesock
      return kill_client_socket(client_socket) if @embed_options[:disable_run]

      client_socket.onclose do |_event|
        runner_socket&.close(:terminated_by_client)
      end

      client_socket.onmessage do |event|
        event = JSON.parse(event).deep_symbolize_keys
        case event[:cmd].to_sym
          when :client_kill
            close_client_connection(client_socket)
            Rails.logger.debug('Client exited container.')
          when :result
            # The client cannot send something before the runner connection is established.
            if runner_socket.present?
              runner_socket.send event[:data]
            else
              Rails.logger.info("Could not forward data from client because runner connection was not established yet: #{event[:data].inspect}")
            end
          else
            Rails.logger.info("Unknown command from client: #{event[:cmd]}")
        end
      rescue JSON::ParserError => e
        Rails.logger.info("Data received from client is not valid json: #{data.inspect}")
        Sentry.set_extras(data: data)
        Sentry.capture_exception(e)
      rescue TypeError => e
        Rails.logger.info("JSON data received from client cannot be parsed as hash: #{data.inspect}")
        Sentry.set_extras(data: data)
        Sentry.capture_exception(e)
      end
    end

    @output = +''
    durations = @submission.run(sanitize_filename) do |socket|
      runner_socket = socket
      client_socket.send_data JSON.dump({cmd: :status, status: :container_running})

      runner_socket.on :stdout do |data|
        json_data = JSON.dump({cmd: :write, stream: :stdout, data: data})
        @output << json_data[0, max_output_buffer_size - @output.size]
        client_socket.send_data(json_data)
      end

      runner_socket.on :stderr do |data|
        json_data = JSON.dump({cmd: :write, stream: :stderr, data: data})
        @output << json_data[0, max_output_buffer_size - @output.size]
        client_socket.send_data(json_data)
      end

      runner_socket.on :exit do |exit_code|
        if @output.empty?
          client_socket.send_data JSON.dump({cmd: :write, stream: :stdout, data: "#{t('exercises.implement.no_output', timestamp: l(Time.zone.now, format: :short))}\n"})
        end
        client_socket.send_data JSON.dump({cmd: :write, stream: :stdout, data: "#{t('exercises.implement.exit', exit_code: exit_code)}\n"})
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

  def extract_durations(error)
    @container_execution_time = error.execution_duration
    @waiting_for_container_time = error.waiting_duration
  end
  private :extract_durations

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
      return if @embed_options[:disable_run]

      tubesock.send_data(JSON.dump(@submission.calculate_score))
      # To enable hints when scoring a submission, uncomment the next line:
      # send_hints(tubesock, StructuredError.where(submission: @submission))
    rescue Runner::Error => e
      tubesock.send_data JSON.dump({cmd: :status, status: :container_depleted})
      Rails.logger.debug { "Runner error while scoring submission #{@submission.id}: #{e.message}" }
    ensure
      kill_client_socket(tubesock)
    end
  end

  def send_hints(tubesock, errors)
    return if @embed_options[:disable_hints]

    errors = errors.to_a.uniq(&:hint)
    errors.each do |error|
      tubesock.send_data JSON.dump({cmd: 'hint', hint: error.hint, description: error.error_template.description})
    end
  end

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
  # TODO: add this method to the before action for set_submission again
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
