# frozen_string_literal: true

require 'rails_helper'

describe ProformaService::ConvertTaskToExercise do
  # TODO: Add teacher_defined_linter for tests

  describe '.new' do
    subject(:convert_to_exercise_service) { described_class.new(task: task, user: user, exercise: exercise) }

    let(:task) { Proforma::Task.new }
    let(:user) { FactoryBot.build(:teacher) }
    let(:exercise) { FactoryBot.build(:dummy) }

    it 'assigns task' do
      expect(convert_to_exercise_service.instance_variable_get(:@task)).to be task
    end

    it 'assigns user' do
      expect(convert_to_exercise_service.instance_variable_get(:@user)).to be user
    end

    it 'assigns exercise' do
      expect(convert_to_exercise_service.instance_variable_get(:@exercise)).to be exercise
    end
  end

  describe '#execute' do
    subject(:convert_to_exercise_service) { described_class.call(task: task, user: user, exercise: exercise) }

    before { FactoryBot.create(:dot_txt) }

    let(:task) do
      Proforma::Task.new(
        title: 'title',
        description: 'description',
        internal_description: 'internal_description',
        proglang: {name: 'proglang-name', version: 'proglang-version'},
        uuid: 'uuid',
        parent_uuid: 'parent_uuid',
        language: 'language',
        model_solutions: model_solutions,
        files: files,
        tests: tests
      )
    end
    let(:user) { FactoryBot.create(:teacher) }
    let(:files) { [] }
    let(:tests) { [] }
    let(:model_solutions) { [] }
    let(:exercise) { nil }

    it 'creates an exercise with the correct attributes' do
      expect(convert_to_exercise_service).to have_attributes(
        title: 'title',
        description: 'description',
        instructions: 'internal_description',
        execution_environment: be_blank,
        uuid: be_blank,
        unpublished: true,
        user: user,
        files: be_empty
      )
    end

    context 'when task has a file' do
      let(:files) { [file] }
      let(:file) do
        Proforma::TaskFile.new(
          id: 'id',
          content: content,
          filename: filename,
          used_by_grader: 'used_by_grader',
          visible: 'yes',
          usage_by_lms: usage_by_lms,
          binary: binary,
          internal_description: 'regular_file',
          mimetype: mimetype
        )
      end
      let(:filename) { "#{path}filename.txt" }
      let(:usage_by_lms) { 'display' }
      let(:mimetype) { 'mimetype' }
      let(:binary) { false }
      let(:content) { 'content' }
      let(:path) { nil }

      it 'creates an exercise with a file that has the correct attributes' do
        expect(convert_to_exercise_service.files.first).to have_attributes(
          content: 'content',
          name: 'filename',
          role: 'regular_file',
          hidden: false,
          read_only: true,
          file_type: be_a(FileType).and(have_attributes(file_extension: '.txt')),
          path: nil
        )
      end

      it 'creates a new Exercise on save' do
        expect { convert_to_exercise_service.save! }.to change(Exercise, :count).by(1)
      end

      context 'when path is folder/' do
        let(:path) { 'folder/' }

        it 'creates an exercise with a file that has the correct path' do
          expect(convert_to_exercise_service.files.first).to have_attributes(path: 'folder')
        end
      end

      context 'when path is ./' do
        let(:path) { './' }

        it 'creates an exercise with a file that has the correct path' do
          expect(convert_to_exercise_service.files.first).to have_attributes(path: nil)
        end
      end

      context 'when file is very large' do
        let(:content) { 'test' * 10**5 }

        it 'creates an exercise with a file that has the correct attributes' do
          expect(convert_to_exercise_service.files.first).to have_attributes(content: content)
        end
      end

      context 'when file is binary' do
        let(:mimetype) { 'image/png' }
        let(:binary) { true }

        it 'creates an exercise with a file with attachment and the correct attributes' do
          expect(convert_to_exercise_service.files.first.native_file).to be_present
        end
      end

      context 'when usage_by_lms is edit' do
        let(:usage_by_lms) { 'edit' }

        it 'creates an exercise with a file with correct attributes' do
          expect(convert_to_exercise_service.files.first).to have_attributes(read_only: false)
        end
      end

      context 'when file is a model-solution-placeholder (needed by proforma until issue #5 is resolved)' do
        let(:file) { Proforma::TaskFile.new(id: 'ms-placeholder-file') }

        it 'leaves exercise_files empty' do
          expect(convert_to_exercise_service.files).to be_empty
        end
      end

      context 'when file has an unkown file_type' do
        let(:filename) { 'unknown_file_type.asdf' }

        it 'creates a new Exercise on save' do
          expect { convert_to_exercise_service.save! }.to change(Exercise, :count).by(1)
        end

        it 'creates the missing FileType on save' do
          expect { convert_to_exercise_service.save! }.to change(FileType, :count).by(1)
        end
      end
    end

    context 'when task has a model-solution' do
      let(:model_solutions) { [model_solution] }
      let(:model_solution) do
        Proforma::ModelSolution.new(
          id: 'ms-id',
          files: ms_files
        )
      end
      let(:ms_files) { [ms_file] }
      let(:ms_file) do
        Proforma::TaskFile.new(
          id: 'ms-file',
          content: 'content',
          filename: 'filename.txt',
          used_by_grader: 'used_by_grader',
          visible: 'yes',
          usage_by_lms: 'display',
          binary: false,
          internal_description: 'reference_implementation'
        )
      end

      it 'creates an exercise with a file with role Reference Implementation' do
        expect(convert_to_exercise_service.files.first).to have_attributes(
          role: 'reference_implementation'
        )
      end

      context 'when task has two model-solutions' do
        let(:model_solutions) { [model_solution, model_solution2] }
        let(:model_solution2) do
          Proforma::ModelSolution.new(
            id: 'ms-id-2',
            files: ms_files2
          )
        end
        let(:ms_files2) { [ms_file2] }
        let(:ms_file2) do
          Proforma::TaskFile.new(
            id: 'ms-file-2',
            content: 'content',
            filename: 'filename.txt',
            used_by_grader: 'used_by_grader',
            visible: 'yes',
            usage_by_lms: 'display',
            binary: false,
            internal_description: 'reference_implementation'
          )
        end

        it 'creates an exercise with two files with role Reference Implementation' do
          expect(convert_to_exercise_service.files).to have(2).items.and(all(have_attributes(role: 'reference_implementation')))
        end
      end
    end

    context 'when task has a test' do
      let(:tests) { [test] }
      let(:test) do
        Proforma::Test.new(
          id: 'test-id',
          title: 'title',
          description: 'description',
          internal_description: 'internal_description',
          test_type: 'test_type',
          files: test_files,
          meta_data: [
            {namespace: 'openHPI', key: 'feedback-message', value: 'feedback-message'},
            {namespace: 'openHPI', key: 'testing-framework', value: 'testing-framework'},
            {namespace: 'openHPI', key: 'testing-framework-version', value: 'testing-framework-version'},
          ]
        )
      end

      let(:test_files) { [test_file] }
      let(:test_file) do
        Proforma::TaskFile.new(
          id: 'test_file_id',
          content: 'testfile-content',
          filename: 'testfile.txt',
          used_by_grader: 'yes',
          visible: 'no',
          usage_by_lms: 'display',
          binary: false,
          internal_description: 'teacher_defined_test'
        )
      end

      it 'creates an exercise with a test' do
        expect(convert_to_exercise_service.files.select {|file| file.role == 'teacher_defined_test' }).to have(1).item
      end

      it 'creates an exercise with a test with correct attributes' do
        expect(convert_to_exercise_service.files.find {|file| file.role == 'teacher_defined_test' }).to have_attributes(
          feedback_message: 'feedback-message',
          content: 'testfile-content',
          name: 'testfile',
          role: 'teacher_defined_test',
          hidden: true,
          read_only: true,
          file_type: be_a(FileType).and(have_attributes(file_extension: '.txt'))
        )
      end

      context 'when task has multiple tests' do
        let(:tests) { [test, test2] }
        let(:test2) do
          Proforma::Test.new(
            files: test_files2,
            meta_data: [
              {namespace: 'openHPI', key: 'feedback-message', value: 'feedback-message'},
              {namespace: 'openHPI', key: 'testing-framework', value: 'testing-framework'},
              {namespace: 'openHPI', key: 'testing-framework-version', value: 'testing-framework-version'},
            ]
          )
        end
        let(:test_files2) { [test_file2] }
        let(:test_file2) do
          Proforma::TaskFile.new(
            id: 'test_file_id2',
            content: 'testfile-content',
            filename: 'testfile.txt',
            used_by_grader: 'yes',
            visible: 'no',
            usage_by_lms: 'display',
            binary: false,
            internal_description: 'teacher_defined_test'
          )
        end

        it 'creates an exercise with two test' do
          expect(convert_to_exercise_service.files.select {|file| file.role == 'teacher_defined_test' }).to have(2).items
        end
      end
    end

    context 'when exercise is set' do
      let(:exercise) do
        FactoryBot.create(
          :files,
          title: 'exercise-title',
          description: 'exercise-description',
          instructions: 'exercise-instruction'
        )
      end

      before { exercise.reload }

      it 'assigns all values to given exercise' do
        convert_to_exercise_service.save
        expect(exercise.reload).to have_attributes(
          id: exercise.id,
          title: task.title,
          description: task.description,
          instructions: task.internal_description,
          execution_environment: exercise.execution_environment,
          uuid: exercise.uuid,
          user: exercise.user,
          files: be_empty
        )
      end

      it 'does not create a new Exercise on save' do
        expect { convert_to_exercise_service.save }.not_to change(Exercise, :count)
      end

      context 'with file, model solution and test' do
        let(:files) { [file] }
        let(:file) do
          Proforma::TaskFile.new(
            id: 'id',
            content: 'content',
            filename: 'filename.txt',
            used_by_grader: 'used_by_grader',
            visible: 'yes',
            usage_by_lms: 'display',
            binary: false,
            internal_description: 'regular_file'
          )
        end
        let(:tests) { [test] }
        let(:test) do
          Proforma::Test.new(
            id: 'test-id',
            title: 'title',
            description: 'description',
            internal_description: 'regular_file',
            test_type: 'test_type',
            files: test_files,
            meta_data: [
              {namespace: 'openHPI', key: 'feedback-message', value: 'feedback-message'},
              {namespace: 'openHPI', key: 'testing-framework', value: 'testing-framework'},
              {namespace: 'openHPI', key: 'testing-framework-version', value: 'testing-framework-version'},
            ]
          )
        end
        let(:test_files) { [test_file] }
        let(:test_file) do
          Proforma::TaskFile.new(
            id: 'test_file_id',
            content: 'testfile-content',
            filename: 'testfile.txt',
            used_by_grader: 'yes',
            visible: 'no',
            usage_by_lms: 'display',
            binary: false,
            internal_description: 'teacher_defined_test'
          )
        end
        let(:model_solutions) { [model_solution] }
        let(:model_solution) do
          Proforma::ModelSolution.new(
            id: 'ms-id',
            files: ms_files
          )
        end
        let(:ms_files) { [ms_file] }
        let(:ms_file) do
          Proforma::TaskFile.new(
            id: 'ms-file',
            content: 'ms-content',
            filename: 'filename.txt',
            used_by_grader: 'used_by_grader',
            visible: 'yes',
            usage_by_lms: 'display',
            binary: false,
            internal_description: 'reference_implementation'
          )
        end

        it 'assigns all values to given exercise' do
          expect(convert_to_exercise_service).to have_attributes(
            id: exercise.id,
            files: have(3).items
              .and(include(have_attributes(content: 'ms-content', role: 'reference_implementation')))
              .and(include(have_attributes(content: 'content', role: 'regular_file')))
              .and(include(have_attributes(content: 'testfile-content', role: 'teacher_defined_test')))
          )
        end
      end
    end
  end
end
