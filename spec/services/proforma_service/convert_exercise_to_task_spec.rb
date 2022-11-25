# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProformaService::ConvertExerciseToTask do
  describe '.new' do
    subject(:convert_to_task) { described_class.new(exercise:) }

    let(:exercise) { build(:dummy) }

    it 'assigns exercise' do
      expect(convert_to_task.instance_variable_get(:@exercise)).to be exercise
    end
  end

  describe '#execute' do
    subject(:task) { convert_to_task.execute }

    let(:convert_to_task) { described_class.new(exercise:) }
    let(:exercise) do
      create(:dummy,
        execution_environment:,
        instructions: 'instruction',
        uuid: SecureRandom.uuid,
        files: files + tests)
    end
    let(:files) { [] }
    let(:tests) { [] }
    let(:execution_environment) { create(:java) }

    it 'creates a task with all basic attributes' do
      expect(task).to have_attributes(
        title: exercise.title,
        description: exercise.description,
        uuid: exercise.uuid,
        language: described_class::DEFAULT_LANGUAGE,
        meta_data: {
          CodeOcean: {
            allow_auto_completion: exercise.allow_auto_completion,
            allow_file_creation: exercise.allow_file_creation,
            execution_environment_id: exercise.execution_environment_id,
            expected_difficulty: exercise.expected_difficulty,
            hide_file_tree: exercise.hide_file_tree,
            public: exercise.public,
            files: {},
          },
        },
        files: [],
        tests: [],
        model_solutions: []
      )
    end

    context 'when exercise has execution_environment with correct docker-image name' do
      it 'creates a task with the correct proglang attribute' do
        expect(task).to have_attributes(proglang: {name: 'java', version: '8'})
      end
    end

    context 'when exercise has a mainfile' do
      let(:files) { [file] }
      let(:file) { build(:file) }

      it 'creates a task-file with the correct attributes' do
        expect(task.files.first).to have_attributes(
          id: file.id,
          content: file.content,
          filename: file.name_with_extension,
          used_by_grader: true,
          usage_by_lms: 'edit',
          visible: 'yes',
          binary: false,
          internal_description: nil
        )
      end

      it 'adds the file\'s role to the file hash in task-meta_data' do
        expect(task).to have_attributes(
          meta_data: {
            CodeOcean: a_hash_including(files: {"CO-#{file.id}" => {role: 'main_file'}}),
          }
        )
      end
    end

    context 'when exercise has a regular file' do
      let(:files) { [file] }
      let(:file) { build(:file, role: 'regular_file', hidden:, read_only:) }
      let(:hidden) { true }
      let(:read_only) { true }

      it 'creates a task-file with the correct attributes' do
        expect(task.files.first).to have_attributes(
          id: file.id,
          content: file.content,
          filename: file.name_with_extension,
          used_by_grader: true,
          usage_by_lms: 'display',
          visible: 'no',
          binary: false,
          internal_description: nil
        )
      end

      it 'adds the file\'s role to the file hash in task-meta_data' do
        expect(task).to have_attributes(
          meta_data: {
            CodeOcean: a_hash_including(files: {"CO-#{file.id}" => {role: 'regular_file'}}),
          }
        )
      end

      context 'when file is not hidden' do
        let(:hidden) { false }

        it 'creates a task-file with the correct attributes' do
          expect(task.files.first).to have_attributes(visible: 'yes')
        end
      end

      context 'when file is not read_only' do
        let(:read_only) { false }

        it 'creates a task-file with the correct attributes' do
          expect(task.files.first).to have_attributes(usage_by_lms: 'edit')
        end
      end

      context 'when file has an attachment' do
        let(:file) { build(:file, :image, role: 'regular_file') }

        it 'creates a task-file with the correct attributes' do
          expect(task.files.first).to have_attributes(
            used_by_grader: false,
            binary: true,
            mimetype: 'image/png'
          )
        end
      end
    end

    context 'when exercise has a file with role reference implementation' do
      let(:files) { [file] }
      let(:file) { build(:file, role: 'reference_implementation') }

      it 'creates a task with one model-solution' do
        expect(task.model_solutions).to have(1).item
      end

      it 'creates a model-solution with one file' do
        expect(task.model_solutions.first).to have_attributes(
          id: "ms-#{file.id}",
          files: have(1).item
        )
      end

      it 'creates a model-solution with one file with correct attributes' do
        expect(task.model_solutions.first.files.first).to have_attributes(
          id: file.id,
          content: file.content,
          filename: file.name_with_extension,
          used_by_grader: false,
          usage_by_lms: 'display',
          visible: 'yes',
          binary: false,
          internal_description: nil
        )
      end
    end

    context 'when exercise has multiple files with role reference implementation' do
      let(:files) { build_list(:file, 2, role: 'reference_implementation') }

      it 'creates a task with two model-solutions' do
        expect(task.model_solutions).to have(2).items
      end
    end

    context 'when exercise has a test' do
      let(:tests) { [test_file] }
      let(:test_file) { build(:test_file) }
      # let(:file) { FactoryBot.build(:codeharbor_test_file) }

      it 'creates a task with one test' do
        expect(task.tests).to have(1).item
      end

      it 'creates a test with one file' do
        expect(task.tests.first).to have_attributes(
          id: test_file.id,
          title: test_file.name,
          files: have(1).item,
          meta_data: {
            CodeOcean: {
              'feedback-message': 'feedback_message',
              weight: test_file.weight,
            },
          }
        )
      end

      it 'creates a test with one file with correct attributes' do
        expect(task.tests.first.files.first).to have_attributes(
          id: test_file.id,
          content: test_file.content,
          filename: test_file.name_with_extension,
          used_by_grader: true,
          visible: 'no',
          binary: false,
          internal_description: nil
        )
      end

      context 'when exercise_file is not hidden' do
        let(:test_file) { create(:test_file, hidden: false) }

        it 'creates the test file with the correct attribute' do
          expect(task.tests.first.files.first).to have_attributes(visible: 'yes')
        end
      end
    end

    context 'when exercise has multiple tests' do
      let(:tests) { build_list(:test_file, 2) }

      it 'creates a task with two tests' do
        expect(task.tests).to have(2).items
      end
    end
  end
end
