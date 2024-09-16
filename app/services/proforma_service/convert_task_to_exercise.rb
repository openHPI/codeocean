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
        public: string_to_bool(extract_meta_data(@task.meta_data&.dig('meta-data'), 'public')) || false,
        hide_file_tree: string_to_bool(extract_meta_data(@task.meta_data&.dig('meta-data'), 'hide_file_tree')) || false,
        allow_file_creation: string_to_bool(extract_meta_data(@task.meta_data&.dig('meta-data'), 'allow_file_creation')) || false,
        allow_auto_completion: string_to_bool(extract_meta_data(@task.meta_data&.dig('meta-data'), 'allow_auto_completion')) || false,
        expected_difficulty: extract_meta_data(@task.meta_data&.dig('meta-data'), 'expected_difficulty') || 1,
        execution_environment_id:,

        files:
      )
    end

    def extract_meta_data(meta_data, *path)
      current_level = meta_data
      path.each {|attribute| current_level = current_level&.dig("CodeOcean:#{attribute}") }
      current_level&.dig('$1')
    end

    def execution_environment_id
      from_meta_data = extract_meta_data(@task.meta_data&.dig('meta-data'), 'execution_environment_id')
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
      model_solution_files + test_files + task_files
    end

    def test_files
      @task.tests.flat_map do |test|
        test.files.map do |task_file|
          codeocean_file_from_task_file(task_file, test).tap do |file|
            file.weight = extract_meta_data(test.meta_data&.dig('test-meta-data'), 'test-file', task_file.id, 'weight').presence || 1.0
            file.feedback_message = extract_meta_data(test.meta_data&.dig('test-meta-data'), 'test-file', task_file.id, 'feedback-message').presence || 'Feedback'
            file.hidden_feedback = extract_meta_data(test.meta_data&.dig('test-meta-data'), 'test-file', task_file.id, 'hidden-feedback').presence || false
            file.role = 'teacher_defined_test' unless file.teacher_defined_assessment?
          end
        end
      end
    end

    def model_solution_files
      @task.model_solutions.flat_map do |model_solution|
        model_solution.files.map do |task_file|
          codeocean_file_from_task_file(task_file, model_solution).tap do |file|
            file.role ||= 'reference_implementation'
          end
        end
      end
    end

    def task_files
      @task.files.reject {|file| file.id == 'ms-placeholder-file' }.map do |task_file|
        codeocean_file_from_task_file(task_file).tap do |file|
          file.role ||= 'regular_file'
        end
      end
    end

    def codeocean_file_from_task_file(file, parent_object = nil)
      extension = File.extname(file.filename)

      codeocean_file = CodeOcean::File.where(context: @exercise).where('xml_id_path = ? OR xml_id_path LIKE ?', file.id, "%/#{file.id}").first_or_initialize(context: @exercise)
      codeocean_file.assign_attributes(
        context: @exercise,
        file_type: file_type(extension),
        hidden: file.visible != 'yes', # hides 'delayed' and 'no'
        name: File.basename(file.filename, '.*'),
        read_only: file.usage_by_lms != 'edit',
        role: extract_meta_data(@task.meta_data&.dig('meta-data'), 'files', "CO-#{file.id}", 'role'),
        path: File.dirname(file.filename).in?(['.', '']) ? nil : File.dirname(file.filename),
        xml_id_path: (parent_object.nil? ? '' : "#{parent_object.id}/") + file.id.to_s
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
