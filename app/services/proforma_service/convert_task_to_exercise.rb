# frozen_string_literal: true

module ProformaService
  class ConvertTaskToExercise < ServiceBase
    def initialize(task:, user:, exercise: nil)
      super()
      @task = task
      @user = user
      @exercise = exercise || Exercise.new(unpublished: true)
    end

    def execute
      import_task
      @exercise
    end

    private

    def import_task
      @exercise.assign_attributes(
        user: @user,
        title: @task.title,
        description: @task.description,
        public: string_to_bool(@task.meta_data[:CodeOcean]&.dig(:public)) || false,
        hide_file_tree: string_to_bool(@task.meta_data[:CodeOcean]&.dig(:hide_file_tree)) || false,
        allow_file_creation: string_to_bool(@task.meta_data[:CodeOcean]&.dig(:allow_file_creation)) || false,
        allow_auto_completion: string_to_bool(@task.meta_data[:CodeOcean]&.dig(:allow_auto_completion)) || false,
        expected_difficulty: @task.meta_data[:CodeOcean]&.dig(:expected_difficulty) || 1,
        execution_environment_id:,

        files:
      )
    end

    def execution_environment_id
      from_meta_data = @task.meta_data[:CodeOcean]&.dig(:execution_environment_id)
      return from_meta_data if from_meta_data
      return nil unless @task.proglang

      ex_envs_with_name_and_version = ExecutionEnvironment.where('docker_image ilike ?', "%#{@task.proglang[:name]}%#{@task.proglang[:version]}%")
      return ex_envs_with_name_and_version.first.id if ex_envs_with_name_and_version.any?

      ex_envs_with_name = ExecutionEnvironment.where('docker_image like ?', "%#{@task.proglang[:name]}%")
      return ex_envs_with_name.first.id if ex_envs_with_name.any?

      nil
    end

    def string_to_bool(str)
      return true if str == 'true'
      return false if str == 'false'

      nil
    end

    def files
      model_solution_files + test_files + task_files.values.tap {|array| array.each {|file| file.role ||= 'regular_file' } }
    end

    def test_files
      @task.tests.map do |test_object|
        task_files.delete(test_object.files.first.id).tap do |file|
          file.weight = test_object.meta_data[:CodeOcean]&.dig(:weight) || 1.0
          file.feedback_message = test_object.meta_data[:CodeOcean]&.dig(:'feedback-message').presence || 'Feedback'
          file.role ||= 'teacher_defined_test'
        end
      end
    end

    def model_solution_files
      @task.model_solutions.map do |model_solution_object|
        task_files.delete(model_solution_object.files.first.id).tap do |file|
          file.role ||= 'reference_implementation'
        end
      end
    end

    def task_files
      @task_files ||= @task.all_files.reject {|file| file.id == 'ms-placeholder-file' }.to_h do |task_file|
        [task_file.id, codeocean_file_from_task_file(task_file)]
      end
    end

    def codeocean_file_from_task_file(file)
      extension = File.extname(file.filename)
      codeocean_file = CodeOcean::File.new(
        context: @exercise,
        file_type: file_type(extension),
        hidden: file.visible != 'yes', # hides 'delayed' and 'no'
        name: File.basename(file.filename, '.*'),
        read_only: file.usage_by_lms != 'edit',
        role: @task.meta_data[:CodeOcean]&.dig(:files)&.dig("CO-#{file.id}".to_sym)&.dig(:role),
        path: File.dirname(file.filename).in?(['.', '']) ? nil : File.dirname(file.filename)
      )
      if file.binary
        codeocean_file.native_file = FileIO.new(file.content.dup.force_encoding('UTF-8'), File.basename(file.filename))
      else
        codeocean_file.content = file.content
      end
      codeocean_file
    end

    def file_type(extension)
      FileType.find_or_create_by(file_extension: extension) do |file_type|
        file_type.name = "Imported #{extension}"
        file_type.user = @user
        file_type.indent_size = 4
        file_type.editor_mode = 'ace/mode/plain_text'
      end
    end
  end
end
