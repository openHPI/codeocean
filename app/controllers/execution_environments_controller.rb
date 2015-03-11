class ExecutionEnvironmentsController < ApplicationController
  include CommonBehavior

  before_action :set_docker_images, only: [:create, :edit, :new, :update]
  before_action :set_execution_environment, only: MEMBER_ACTIONS + [:execute_command, :shell]
  before_action :set_testing_framework_adapters, only: [:create, :edit, :new, :update]

  def authorize!
    authorize(@execution_environment || @execution_environments)
  end
  private :authorize!

  def create
    @execution_environment = ExecutionEnvironment.new(execution_environment_params)
    authorize!
    create_and_respond(object: @execution_environment)
  end

  def destroy
    destroy_and_respond(object: @execution_environment)
  end

  def edit
  end

  def execute_command
    @docker_client = DockerClient.new(execution_environment: @execution_environment)
    render(json: @docker_client.execute_arbitrary_command(params[:command]))
  end

  def execution_environment_params
    params[:execution_environment].permit(:docker_image, :exposed_ports, :editor_mode, :file_extension, :file_type_id, :help, :indent_size, :name, :permitted_execution_time, :pool_size, :run_command, :test_command, :testing_framework).merge(user_id: current_user.id, user_type: current_user.class.name)
  end
  private :execution_environment_params

  def index
    @execution_environments = ExecutionEnvironment.all.includes(:user).order(:name).paginate(page: params[:page])
    authorize!
  end

  def new
    @execution_environment = ExecutionEnvironment.new
    authorize!
  end

  def set_docker_images
    DockerClient.check_availability!
    @docker_images = DockerClient.image_tags.sort
  rescue DockerClient::Error => error
    @docker_images = []
    flash[:warning] = error.message
  end
  private :set_docker_images

  def set_execution_environment
    @execution_environment = ExecutionEnvironment.find(params[:id])
    authorize!
  end
  private :set_execution_environment

  def set_testing_framework_adapters
    Rails.application.eager_load!
    @testing_framework_adapters = TestingFrameworkAdapter.descendants.sort_by(&:framework_name).map do |klass|
      [klass.framework_name, klass.name]
    end
  end
  private :set_testing_framework_adapters

  def shell
  end

  def show
    if @execution_environment.testing_framework?
      @testing_framework_adapter = Kernel.const_get(@execution_environment.testing_framework)
    end
  end

  def update
    update_and_respond(object: @execution_environment, params: execution_environment_params)
  end
end
