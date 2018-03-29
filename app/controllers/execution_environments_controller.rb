class ExecutionEnvironmentsController < ApplicationController
  include CommonBehavior

  before_action :set_docker_images, only: [:create, :edit, :new, :update]
  before_action :set_execution_environment, only: MEMBER_ACTIONS + [:execute_command, :shell, :statistics]
  before_action :set_testing_framework_adapters, only: [:create, :edit, :new, :update]
  skip_after_action :verify_authorized, only: [:proglang_versions]

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


  def working_time_query
    """
      SELECT exercise_id, avg(working_time) as average_time, stddev_samp(extract('epoch' from working_time)) * interval '1 second' as stddev_time
      FROM
        (
      SELECT user_id,
             exercise_id,
             sum(working_time_new) AS working_time
      FROM
        (SELECT user_id,
                exercise_id,
                CASE WHEN working_time >= '0:05:00' THEN '0' ELSE working_time END AS working_time_new
         FROM
            (SELECT user_id,
                    exercise_id,
                    id,
                    (created_at - lag(created_at) over (PARTITION BY user_id, exercise_id
                                                        ORDER BY created_at)) AS working_time
            FROM submissions
            WHERE exercise_id IN (SELECT ID FROM exercises WHERE execution_environment_id = #{@execution_environment.id})
            GROUP BY exercise_id, user_id, id) AS foo) AS bar
      GROUP BY user_id, exercise_id
    ) AS baz GROUP BY exercise_id;
    """
  end

  def user_query
    """
    SELECT
      id AS exercise_id,
      COUNT(DISTINCT user_id) AS users,
      AVG(score) AS average_score,
      MAX(score) AS maximum_score,
      stddev_samp(score) as stddev_score,
      CASE
        WHEN MAX(score)=0 THEN 0
        ELSE 100 / MAX(score) * AVG(score)
      END AS percent_correct,
      SUM(submission_count) / COUNT(DISTINCT user_id) AS average_submission_count
    FROM
      (SELECT e.id,
              s.user_id,
              MAX(s.score) AS score,
              COUNT(s.id) AS submission_count
       FROM submissions s
       JOIN exercises e ON e.id = s.exercise_id
       WHERE e.execution_environment_id = #{@execution_environment.id}
       GROUP BY e.id,
                s.user_id) AS inner_query
    GROUP BY id;
    """
  end

  def statistics
    working_time_statistics = {}
    user_statistics = {}

    ActiveRecord::Base.connection.execute(working_time_query).each do |tuple|
      working_time_statistics[tuple["exercise_id"].to_i] = tuple
    end

    ActiveRecord::Base.connection.execute(user_query).each do |tuple|
      user_statistics[tuple["exercise_id"].to_i] = tuple
    end

    render locals: {
      working_time_statistics: working_time_statistics,
      user_statistics: user_statistics
    }
  end

  def execution_environment_params
    params[:execution_environment].permit(:docker_image, :exposed_ports, :editor_mode, :file_extension, :file_type_id, :help, :indent_size, :memory_limit, :name, :network_enabled, :permitted_execution_time, :pool_size, :run_command, :test_command, :testing_framework, programming_languages_joins_attributes: [:id, :programming_language_id, :default, :_destroy]).merge(user_id: current_user.id, user_type: current_user.class.name)
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
