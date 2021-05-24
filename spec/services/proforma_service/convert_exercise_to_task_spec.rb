# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProformaService::ConvertExerciseToTask do
  describe '.new' do
    subject(:convert_to_task) { described_class.new(exercise: exercise) }

    let(:exercise) { FactoryBot.build(:dummy) }

    it 'assigns exercise' do
      expect(convert_to_task.instance_variable_get(:@exercise)).to be exercise
    end
  end

  describe '#execute' do
    subject(:task) { convert_to_task.execute }

    let(:convert_to_task) { described_class.new(exercise: exercise) }
    let(:exercise) do
      FactoryBot.create(:dummy,
        instructions: 'instruction',
        uuid: SecureRandom.uuid,
        files: files + tests)
    end
    let(:files) { [] }
    let(:tests) { [] }

    it 'creates a task with all basic attributes' do
      expect(task).to have_attributes(
        title: exercise.title,
        description: exercise.description,
        internal_description: exercise.instructions,
        # proglang: {
        #   name: exercise.execution_environment.language,
        #   version: exercise.execution_environment.version
        # },
        uuid: exercise.uuid,
        language: described_class::DEFAULT_LANGUAGE,
        # parent_uuid: exercise.clone_relations.first&.origin&.uuid,
        files: [],
        tests: [],
        model_solutions: []
      )
    end

    context 'when exercise has a mainfile' do
      let(:files) { [file] }
      let(:file) { FactoryBot.build(:file) }

      it 'creates a task-file with the correct attributes' do
        expect(task.files.first).to have_attributes(
          id: file.id,
          content: file.content,
          filename: file.name_with_extension,
          used_by_grader: true,
          usage_by_lms: 'edit',
          visible: 'yes',
          binary: false,
          internal_description: 'main_file'
        )
      end
    end

    context 'when exercise has a regular file' do
      let(:files) { [file] }
      let(:file) { FactoryBot.build(:file, role: 'regular_file', hidden: hidden, read_only: read_only) }
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
          internal_description: 'regular_file'
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
        let(:file) { FactoryBot.build(:file, :image, role: 'regular_file') }

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
      let(:file) { FactoryBot.build(:file, role: 'reference_implementation') }

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
          internal_description: 'reference_implementation'
        )
      end
    end

    context 'when exercise has multiple files with role reference implementation' do
      let(:files) { FactoryBot.build_list(:file, 2, role: 'reference_implementation') }

      it 'creates a task with two model-solutions' do
        expect(task.model_solutions).to have(2).items
      end
    end

    context 'when exercise has a test' do
      let(:tests) { [test_file] }
      let(:test_file) { FactoryBot.build(:test_file) }
      # let(:file) { FactoryBot.build(:codeharbor_test_file) }

      it 'creates a task with one test' do
        expect(task.tests).to have(1).item
      end

      it 'creates a test with one file' do
        expect(task.tests.first).to have_attributes(
          id: test_file.id,
          title: test_file.name,
          files: have(1).item,
          meta_data: [{key: 'entry-point', namespace: 'openHPI', value: test_file.filepath},
                      {key: 'feedback-message', namespace: 'openHPI', value: 'feedback_message'}]
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
          internal_description: 'teacher_defined_test'
        )
      end

      context 'when exercise_file is not hidden' do
        let(:test_file) { FactoryBot.create(:test_file, hidden: false) }

        it 'creates the test file with the correct attribute' do
          expect(task.tests.first.files.first).to have_attributes(visible: 'yes')
        end
      end
    end

    context 'when exercise has multiple tests' do
      let(:tests) { FactoryBot.build_list(:test_file, 2) }

      it 'creates a task with two tests' do
        expect(task.tests).to have(2).items
      end
    end
  end
end
