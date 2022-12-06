# frozen_string_literal: true

class ExecutionEnvironmentsController < ApplicationController
  include CommonBehavior
  include FileConversion
  include TimeHelper

  before_action :set_docker_images, only: %i[create edit new update]
  before_action :set_execution_environment, only: MEMBER_ACTIONS + %i[execute_command shell list_files statistics sync_to_runner_management]
  before_action :set_testing_framework_adapters, only: %i[create edit new update]

  def authorize!
    authorize(@execution_environment || @execution_environments)
  end
  private :authorize!

  def index
    @execution_environments = ExecutionEnvironment.all.includes(:user).order(:name).paginate(page: params[:page], per_page: per_page_param)
    authorize!
  end

  def show
    if @execution_environment.testing_framework?
      @testing_framework_adapter = TestingFrameworkAdapter.descendants.find {|klass| klass.name == @execution_environment.testing_framework }
    end
  end

  def new
    @execution_environment = ExecutionEnvironment.new
    authorize!
  end

  def execute_command
    runner = Runner.for(current_user, @execution_environment)
    @privileged_execution = ActiveModel::Type::Boolean.new.cast(params[:sudo]) || @execution_environment.privileged_execution
    output = runner.execute_command(params[:command], privileged_execution: @privileged_execution, raise_exception: false)
    render json: output.except(:messages)
  end

  def list_files
    runner = Runner.for(current_user, @execution_environment)
    @privileged_execution = ActiveModel::Type::Boolean.new.cast(params[:sudo]) || @execution_environment.privileged_execution
    begin
      files = runner.retrieve_files(path: params[:path], recursive: false, privileged_execution: @privileged_execution)
      downloadable_files, additional_directories = convert_files_json_to_files files
      js_tree = FileTree.new(downloadable_files, additional_directories, force_closed: true).to_js_tree
      render json: js_tree[:core][:data]
    rescue Runner::Error::RunnerNotFound, Runner::Error::WorkspaceError
      render json: []
    end
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
                CASE WHEN #{StatisticsHelper.working_time_larger_delta} THEN '0' ELSE working_time END AS working_time_new
         FROM
            (SELECT user_id,
                    exercise_id,
                    id,
                    (created_at - lag(created_at) over (PARTITION BY user_id, exercise_id
                                                        ORDER BY created_at)) AS working_time
            FROM submissions
            WHERE exercise_id IN (SELECT ID FROM exercises WHERE #{ExecutionEnvironment.sanitize_sql(['execution_environment_id = ?', @execution_environment.id])})
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
       WHERE #{ExecutionEnvironment.sanitize_sql(['e.execution_environment_id = ?', @execution_environment.id])}
       GROUP BY e.id,
                s.user_id) AS inner_query
    GROUP BY id;
    "
  end

  def statistics
    working_time_statistics = {}
    user_statistics = {}

    ApplicationRecord.connection.exec_query(working_time_query).each do |tuple|
      tuple = tuple.merge({
        'average_time' => format_time_difference(tuple['average_time']),
        'stddev_time' => format_time_difference(tuple['stddev_time']),
      })
      working_time_statistics[tuple['exercise_id'].to_i] = tuple
    end

    ApplicationRecord.connection.exec_query(user_query).each do |tuple|
      user_statistics[tuple['exercise_id'].to_i] = tuple
    end

    render locals: {
      working_time_statistics:,
      user_statistics:,
    }
  end

  def execution_environment_params
    if params[:execution_environment].present?
      exposed_ports = if params[:execution_environment][:exposed_ports_list]
                        # Transform the `exposed_ports_list` to `exposed_ports` array
                        params[:execution_environment].delete(:exposed_ports_list).scan(/\d+/)
                      else
                        []
                      end

      params[:execution_environment]
        .permit(:docker_image, :editor_mode, :file_extension, :file_type_id, :help, :indent_size, :memory_limit, :cpu_limit, :name,
          :network_enabled, :privileged_execution, :permitted_execution_time, :pool_size, :run_command, :test_command, :testing_framework)
        .merge(user_id: current_user.id, user_type: current_user.class.name, exposed_ports:)
    end
  end
  private :execution_environment_params

  def edit
    # Add the current execution_environment if not already present in the list
    @docker_images |= [@execution_environment.docker_image]
  end

  def create
    @execution_environment = ExecutionEnvironment.new(execution_environment_params)
    authorize!
    create_and_respond(object: @execution_environment)
  end

  def set_docker_images
    @docker_images ||= ExecutionEnvironment.pluck(:docker_image)
    @docker_images += Runner.strategy_class.available_images
  rescue Runner::Error => e
    flash.now[:warning] = ERB::Util.html_escape e.message
  ensure
    @docker_images = @docker_images.sort.uniq
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

  def update
    update_and_respond(object: @execution_environment, params: execution_environment_params)
  end

  def destroy
    destroy_and_respond(object: @execution_environment)
  end

  def sync_to_runner_management
    return unless Runner.management_active?

    begin
      Runner.strategy_class.sync_environment(@execution_environment)
    rescue Runner::Error => e
      Rails.logger.warn { "Runner error while synchronizing execution environment with id #{@execution_environment.id}: #{e.message}" }
      redirect_to @execution_environment, alert: t('execution_environments.index.synchronize.failure', error: ERB::Util.html_escape(e.message))
    else
      redirect_to @execution_environment, notice: t('execution_environments.index.synchronize.success')
    end
  end

  def sync_all_to_runner_management
    authorize ExecutionEnvironment

    return unless Runner.management_active?

    success = []

    begin
      # Get a list of all existing execution environments and mark them as a potential candidate for removal
      environments_to_remove = Runner.strategy_class.environments.pluck(:id)
      success << true
    rescue Runner::Error => e
      Rails.logger.debug { "Runner error while getting all execution environments: #{e.message}" }
      Sentry.capture_exception(e)
      environments_to_remove = []
      success << false
    end

    success += ExecutionEnvironment.all.map do |execution_environment|
      # Sync all current execution environments and prevent deletion of those just synced
      environments_to_remove -= [execution_environment.id]
      Runner.strategy_class.sync_environment(execution_environment)
    rescue Runner::Error => e
      Rails.logger.debug { "Runner error while synchronizing execution environment with id #{execution_environment.id}: #{e.message}" }
      Sentry.capture_exception(e)
      false
    end

    success += environments_to_remove.map do |execution_environment_id|
      # Remove execution environments not synced. We temporarily use a record which is not persisted
      execution_environment = ExecutionEnvironment.new(id: execution_environment_id)
      Runner.strategy_class.remove_environment(execution_environment)
    rescue Runner::Error => e
      Rails.logger.debug { "Runner error while deleting execution environment with id #{execution_environment.id}: #{e.message}" }
      Sentry.capture_exception(e)
      false
    end

    if success.all?
      redirect_to ExecutionEnvironment, notice: t('execution_environments.index.synchronize_all.success')
    else
      redirect_to ExecutionEnvironment, alert: t('execution_environments.index.synchronize_all.failure')
    end
  end

  def augment_files_for_download(files)
    files.map do |file|
      # Downloadable files get an indicator whether we performed a privileged execution.
      # The download path is added dynamically in the frontend.
      file.privileged_execution = @privileged_execution
      file
    end
  end
  private :augment_files_for_download
end
