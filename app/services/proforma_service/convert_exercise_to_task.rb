# frozen_string_literal: true

require 'mimemagic'

module ProformaService
  class ConvertExerciseToTask < ServiceBase
    def initialize(exercise: nil)
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
          internal_description: @exercise.instructions,

          # proglang: proglang,
          files: task_files,
          # tests: tests,
          # uuid: @exercise.uuid,
          # parent_uuid: parent_uuid,
          # language: primary_description.language,
          # model_solutions: model_solutions
        }.compact
      )
    end

    def parent_uuid
      @exercise.clone_relations.first&.origin&.uuid
    end

    def primary_description
      @exercise.descriptions.select(&:primary?).first
    end

    def proglang
      {name: @exercise.execution_environment.language, version: @exercise.execution_environment.version}
    end

    def model_solutions
      @exercise.exercise_files.filter { |file| file.role == 'Reference Implementation' }.map do |file|
        Proforma::ModelSolution.new(
          id: "ms-#{file.id}",
          files: [
            Proforma::TaskFile.new(
              id: file.id,
              content: file.content,
              filename: file.full_file_name,
              used_by_grader: false,
              usage_by_lms: 'display',
              visible: 'delayed',
              binary: false,
              internal_description: file.role
            )
          ]
        )
      end
    end

    def tests
      @exercise.tests.map do |test|
        Proforma::Test.new(
          id: test.id,
          title: test.exercise_file.name,
          files: test_file(test.exercise_file),
          meta_data: {
            'feedback-message' => test.feedback_message,
            'testing-framework' => test.testing_framework&.name,
            'testing-framework-version' => test.testing_framework&.version
          }.compact
        )
      end
    end

    def test_file(file)
      [Proforma::TaskFile.new(
        id: file.id,
        content: file.content,
        filename: file.full_file_name,
        used_by_grader: true,
        visible: file.hidden ? 'no' : 'yes',
        binary: false,
        internal_description: file.role || 'Teacher-defined Test'
      )]
    end

    def task_files
      @exercise.files
               .filter { |file| !file.role.in? %w[reference_implementation teacher_defined_test] }.map do |file|
        task_file(file)
      end
    end

    def task_file(file)
      Proforma::TaskFile.new(
        {
          id: file.id,
          filename: file.path.present? && file.path != '.' ? ::File.join(file.path, file.name_with_extension) : file.name_with_extension,
          usage_by_lms: file.read_only ? 'display' : 'edit',
          visible: file.hidden ? 'no' : 'yes',
          internal_description: file.role || 'regular_file'
        }.tap do |params|
          if file.native_file.present?
            file = ::File.new(file.native_file.file.path, 'r')
            params[:content] = file.read
            params[:used_by_grader] = false
            params[:binary] = true
            params[:mimetype] = MimeMagic.by_magic(file).type
          else
            params[:content] = file.content
            params[:used_by_grader] = true
            params[:binary] = false
          end
        end
      )
    end

    def attachment_content(file)
      Paperclip.io_adapters.for(file.attachment).read
    end
  end
end
