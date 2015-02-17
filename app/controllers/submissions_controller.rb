class SubmissionsController < ApplicationController
  include ActionController::Live
  include CommonBehavior
  include Lti
  include SubmissionParameters
  include SubmissionScoring

  around_action :with_server_sent_events, only: :run
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
    create_and_respond(object: @submission)
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
    @submissions = @search.result.paginate(page: params[:page])
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
    container_id = nil
    stderr = ''
    output = @docker_client.execute_run_command(@submission, params[:filename]) do |stream, chunk|
      unless container_id
        container_id = @docker_client.container_id
        @server_sent_event.write({id: container_id, ports: @docker_client.assigned_ports}, event: 'info')
      end
      @server_sent_event.write({stream => chunk}, event: 'output')
      stderr += chunk if stream == :stderr
    end
    @server_sent_event.write(output, event: 'status')
    if stderr.present?
      if hint = Whistleblower.new(execution_environment: @submission.execution_environment).generate_hint(stderr)
        @server_sent_event.write(hint, event: 'hint')
      else
        store_error(stderr)
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
    container = Docker::Container.get(params[:container_id])
    DockerClient.destroy_container(container)
  rescue Docker::Error::NotFoundError
  ensure
    render(nothing: true)
  end

  def store_error(stderr)
    ::Error.create(execution_environment_id: @submission.exercise.execution_environment_id, message: stderr)
  end
  private :store_error

  def test
    output = @docker_client.execute_test_command(@submission, params[:filename])
    render(json: [output])
  end

  def with_server_sent_events
    response.headers['Content-Type'] = 'text/event-stream'
    @server_sent_event = SSE.new(response.stream)
    @server_sent_event.write(nil, event: 'start')
    yield
    @server_sent_event.write({code: 200}, event: 'close')
  rescue
    @server_sent_event.write({code: 500}, event: 'close')
  ensure
    @server_sent_event.close
  end
  private :with_server_sent_events
end
