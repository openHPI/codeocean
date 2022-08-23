# frozen_string_literal: true

require 'mimemagic'

module ProformaService
  class ConvertExerciseToTask < ServiceBase
    DEFAULT_LANGUAGE = 'de'

    def initialize(exercise: nil)
      super()
      @exercise = exercise
    end

    def execute
      create_task
    end

    private

    def create_task
      Proforma::Task.new(
        {
          title: @exercise.title,
          description: @exercise.description,
          internal_description: nil,
          # proglang: proglang, where can we get this information?
          files: task_files,
          tests: tests,
          uuid: uuid,
          language: DEFAULT_LANGUAGE,
          model_solutions: model_solutions,
          meta_data: {
            CodeOcean: {
              public: @exercise.public,
              hide_file_tree: @exercise.hide_file_tree,
              allow_file_creation: @exercise.allow_file_creation,
              allow_auto_completion: @exercise.allow_auto_completion,
              expected_difficulty: @exercise.expected_difficulty,
              execution_environment_id: @exercise.execution_environment_id,
            },
          },
        }.compact
      )
    end

    def uuid
      @exercise.update(uuid: SecureRandom.uuid) if @exercise.uuid.nil?
      @exercise.uuid
    end

    def model_solutions
      @exercise.files.filter {|file| file.role == 'reference_implementation' }.map do |file|
        Proforma::ModelSolution.new(
          id: "ms-#{file.id}",
          files: model_solution_file(file)
        )
      end
    end

    def model_solution_file(file)
      [
        task_file(file).tap do |ms_file|
          ms_file.used_by_grader = false
          ms_file.usage_by_lms = 'display'
        end,
      ]
    end

    def tests
      @exercise.files.filter do |file|
        file.role == 'teacher_defined_test' || file.role == 'teacher_defined_linter'
      end.map do |file|
        Proforma::Test.new(
          id: file.id,
          title: file.name,
          files: test_file(file),
          meta_data: test_meta_data(file)
        )
      end
    end

    def test_meta_data(file)
      {
        CodeOcean: {
          'feedback-message': file.feedback_message,
          weight: file.weight,
        },
      }
    end

    def test_file(file)
      [
        task_file(file).tap do |t_file|
          t_file.used_by_grader = true
          t_file.internal_description = 'teacher_defined_test'
        end,
      ]
    end

    def task_files
      @exercise.files
        .filter do |file|
        !file.role.in? %w[reference_implementation teacher_defined_test
                          teacher_defined_linter]
      end.map do |file|
        task_file(file)
      end
    end

    def task_file(file)
      task_file = Proforma::TaskFile.new(
        id: file.id,
        filename: filename(file),
        usage_by_lms: file.read_only ? 'display' : 'edit',
        visible: file.hidden ? 'no' : 'yes',
        # internal_description: file.role || 'regular_file'
      )
      add_content_to_task_file(file, task_file)
      task_file
    end

    def filename(file)
      if file.path.present? && file.path != '.'
        ::File.join(file.path,
          file.name_with_extension)
      else
        file.name_with_extension
      end
    end

    def add_content_to_task_file(file, task_file)
      if file.native_file.present?
        file_content = file.read
        task_file.content = file_content
        task_file.used_by_grader = false
        task_file.binary = true
        task_file.mimetype = MimeMagic.by_magic(file_content).type
      else
        task_file.content = file.content
        task_file.used_by_grader = true
        task_file.binary = false
      end
    end
  end
end
