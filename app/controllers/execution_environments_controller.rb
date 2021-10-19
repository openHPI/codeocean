# frozen_string_literal: true

class ExecutionEnvironmentsController < ApplicationController
  include CommonBehavior

  before_action :set_docker_images, only: %i[create edit new update]
  before_action :set_execution_environment, only: MEMBER_ACTIONS + %i[execute_command shell statistics]
  before_action :set_testing_framework_adapters, only: %i[create edit new update]

  def authorize!
    authorize(@execution_environment || @execution_environments)
  end
  private :authorize!

  def create
    @execution_environment = ExecutionEnvironment.new(execution_environment_params)
    authorize!
    create_and_respond(object: @execution_environment) do
      sync_to_runner_management
    end
  end

  def destroy
    destroy_and_respond(object: @execution_environment)
  end

  def edit
    # Add the current execution_environment if not already present in the list
    @docker_images |= [@execution_environment.docker_image]
  end

  def execute_command
    runner = Runner.for(current_user, @execution_environment)
    output = runner.execute_command(params[:command])
    render(json: output)
  end

  def working_time_query
    "
      SELECT exercise_id, avg(working_time) as average_time, stddev_samp(extract('epoch' from working_time)) * interval '1 second' as stddev_time
      FROM
        (
      SELECT user_id,
             exercise_id,
             sum(working_time_new) AS working_time
      FROM
        (SELECT user_id,
                exercise_id,
                CASE WHEN working_time >= #{StatisticsHelper::WORKING_TIME_DELTA_IN_SQL_INTERVAL} THEN '0' ELSE working_time END AS working_time_new
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
    "
  end

  def user_query
    "
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
    "
  end

  def statistics
    working_time_statistics = {}
    user_statistics = {}

    ApplicationRecord.connection.execute(working_time_query).each do |tuple|
      working_time_statistics[tuple['exercise_id'].to_i] = tuple
    end

    ApplicationRecord.connection.execute(user_query).each do |tuple|
      user_statistics[tuple['exercise_id'].to_i] = tuple
    end

    render locals: {
      working_time_statistics: working_time_statistics,
      user_statistics: user_statistics,
    }
  end

  def execution_environment_params
    if params[:execution_environment].present?
      exposed_ports = if params[:execution_environment][:exposed_ports_list].present?
                        # Transform the `exposed_ports_list` to `exposed_ports` array
                        params[:execution_environment].delete(:exposed_ports_list).scan(/\d+/)
                      else
                        []
                      end

      params[:execution_environment].permit(:docker_image, :editor_mode, :file_extension, :file_type_id, :help, :indent_size, :memory_limit, :cpu_limit, :name, :network_enabled, :permitted_execution_time, :pool_size, :run_command, :test_command, :testing_framework).merge(
        user_id: current_user.id, user_type: current_user.class.name, exposed_ports: exposed_ports
      )
    end
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
  rescue DockerClient::Error => e
    @docker_images = []
    flash[:warning] = e.message
    Sentry.capture_exception(e)
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

  def shell; end

  def show
    if @execution_environment.testing_framework?
      @testing_framework_adapter = Kernel.const_get(@execution_environment.testing_framework)
    end
  end

  def update
    update_and_respond(object: @execution_environment, params: execution_environment_params) do
      sync_to_runner_management
    end
  end

  def sync_all_to_runner_management
    authorize ExecutionEnvironment

    return unless Runner.management_active?

    success = ExecutionEnvironment.all.map do |execution_environment|
      Runner.strategy_class.sync_environment(execution_environment)
    end
    if success.all?
      redirect_to ExecutionEnvironment, notice: t('execution_environments.index.synchronize_all.success')
    else
      redirect_to ExecutionEnvironment, alert: t('execution_environments.index.synchronize_all.failure')
    end
  end

  def sync_to_runner_management
    unless Runner.management_active? && Runner.strategy_class.sync_environment(@execution_environment)
      t('execution_environments.form.errors.not_synced_to_runner_management')
    end
  end
  private :sync_to_runner_management
end
