# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProformaService::ConvertTaskToExercise do
  describe '.new' do
    subject(:convert_to_exercise_service) { described_class.new(task:, user:, exercise:) }

    let(:task) { ProformaXML::Task.new }
    let(:user) { build(:teacher) }
    let(:exercise) { build(:dummy) }

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
    subject(:convert_to_exercise_service) { described_class.call(task:, user:, exercise:) }

    before { create(:dot_txt) }

    let(:task) do
      ProformaXML::Task.new(
        title: 'title',
        description:,
        proglang: {name: 'python', version: '3.4'},
        uuid: 'uuid',
        parent_uuid: 'parent_uuid',
        language: 'language',
        meta_data:,
        model_solutions:,
        files:,
        tests:
      )
    end
    let(:user) { create(:teacher) }

    let(:files) { [] }
    let(:tests) { [] }
    let(:model_solutions) { [] }
    let(:exercise) { nil }

    let(:description) { 'description' }
    let(:meta_data) { {} }
    let(:public) { 'true' }
    let(:hide_file_tree) { 'true' }
    let(:allow_file_creation) { 'true' }
    let(:allow_auto_completion) { 'true' }
    let(:expected_difficulty) { 7 }
    let!(:execution_environment) { create(:java) }

    it 'creates an exercise with the correct attributes' do
      expect(convert_to_exercise_service).to have_attributes(
        title: 'title',
        description: 'description',
        uuid: be_blank,
        unpublished: true,
        user:,
        files: be_empty,
        public: false,
        hide_file_tree: false,
        allow_file_creation: false,
        allow_auto_completion: false,
        expected_difficulty: 1,
        execution_environment_id: nil
      )
    end

    it { is_expected.to be_valid }

    context 'when task has no description' do
      let(:description) { nil }

      it 'creates an exercise with the correct description fallback' do
        expect(convert_to_exercise_service).to have_attributes(
                                                 description: 'title'
                                               )
      end
    end

    context 'when meta_data is set' do
      let(:meta_data) do
        {
          '@@order' => ['meta-data'], 'meta-data' =>
          {'@@order' => %w[CodeOcean:public CodeOcean:hide_file_tree CodeOcean:allow_file_creation CodeOcean:allow_auto_completion CodeOcean:expected_difficulty CodeOcean:execution_environment_id CodeOcean:files],
           '@xmlns' => {'CodeOcean' => 'codeocean.openhpi.de'},
           'CodeOcean:allow_auto_completion' => {
             '@@order' => ['$1'],
             '$1' => allow_auto_completion,
           },
           'CodeOcean:allow_file_creation' => {
             '@@order' => ['$1'],
             '$1' => allow_file_creation,
           },
           'CodeOcean:execution_environment_id' => {
             '@@order' => ['$1'],
             '$1' => execution_environment.id,
           },
           'CodeOcean:expected_difficulty' => {
             '@@order' => ['$1'],
             '$1' => expected_difficulty,
           },
           'CodeOcean:files' => {'@@order' => []},
           'CodeOcean:hide_file_tree' => {
             '@@order' => ['$1'],
             '$1' => hide_file_tree,
           },
           'CodeOcean:public' => {
             '@@order' => ['$1'],
             '$1' => public,
           }}
        }
      end
      let(:files_meta_data) { {} }

      it 'creates an exercise with the correct attributes' do
        expect(convert_to_exercise_service).to have_attributes(
          title: 'title',
          description: 'description',
          uuid: be_blank,
          unpublished: true,
          user:,
          files: be_empty,
          public: true,
          hide_file_tree: true,
          allow_file_creation: true,
          allow_auto_completion: true,
          expected_difficulty: 7,
          execution_environment_id: execution_environment.id
        )
      end
    end

    context 'when execution environment is not set in meta_data' do
      let(:execution_environment) { nil }

      before { create(:python) }

      it 'sets the execution_environment based on proglang name and value' do
        expect(convert_to_exercise_service).to have_attributes(execution_environment: have_attributes(name: 'Python 3.4'))
      end
    end

    context 'when task has a file' do
      let(:files) { [file] }
      let(:file) do
        ProformaXML::TaskFile.new(
          id: 'id',
          content:,
          filename:,
          used_by_grader: 'used_by_grader',
          visible: 'yes',
          usage_by_lms:,
          binary:,
          mimetype:
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

      context 'when file is a Makefile' do
        let(:filename) { "#{path}Makefile" }

        it 'creates an exercise with a file with a Filetype, that has the correct attributes' do
          expect(convert_to_exercise_service.files.first).to have_attributes(
            file_type: be_a(FileType).and(have_attributes(file_extension: '', name: 'Imported'))
          )
        end

        context 'when FileType for Makefile exists' do
          let!(:makefile_filetype) { create(:makefile) }

          it 'creates an exercise with a file with a Filetype, that has the correct attributes' do
            expect(convert_to_exercise_service.files.first).to have_attributes(file_type: makefile_filetype)
          end
        end
      end

      context 'when file is a main_file' do
        let(:meta_data) do
          {
            '@@order' => ['meta-data'], 'meta-data' => {
              '@@order' => %w[CodeOcean:files],
              '@xmlns' => {'CodeOcean' => 'codeocean.openhpi.de'},
              'CodeOcean:files' => files_meta_data,
            }
          }
        end
        let(:files_meta_data) do
          {
            '@@order' => ["CodeOcean:CO-#{file.id}"],
            "CodeOcean:CO-#{file.id}" => {
              '@@order' => ['CodeOcean:role'],
              'CodeOcean:role' => {'$1' => 'main_file', '@@order' => ['$1']},
            },
          }
        end

        it 'creates an exercise with a file that has the correct attributes' do
          expect(convert_to_exercise_service.files.first).to have_attributes(role: 'main_file')
        end
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
        let(:content) { 'test' * (10**5) }

        it 'creates an exercise with a file that has the correct attributes' do
          expect(convert_to_exercise_service.files.first).to have_attributes(content:)
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
        let(:file) { ProformaXML::TaskFile.new(id: 'ms-placeholder-file') }

        it 'leaves exercise_files empty' do
          expect(convert_to_exercise_service.files).to be_empty
        end
      end

      context 'when file has an unknown file_type' do
        let(:filename) { 'unknown_file_type.asdf' }

        it 'creates a new Exercise on save' do
          expect { convert_to_exercise_service.save! }.to change(Exercise, :count).by(1)
        end

        it 'creates the missing FileType on save' do
          expect { convert_to_exercise_service.save! }.to change(FileType, :count).by(1)
        end
      end

      context 'when file has a Makefile' do
        let!(:file_type) { create(:makefile) }

        let(:filename) { 'Makefile' }

        it 'creates a new Exercise on save' do
          expect { convert_to_exercise_service.save! }.to change(Exercise, :count).by(1)
        end

        it 'creates an exercise with a file with correct attributes' do
          expect(convert_to_exercise_service.files.first.file_type).to eql file_type
        end
      end
    end

    context 'when task has a model-solution' do
      let(:model_solutions) { [model_solution] }
      let(:model_solution) do
        ProformaXML::ModelSolution.new(
          id: 'ms-id',
          files: ms_files
        )
      end
      let(:ms_files) { [ms_file] }
      let(:ms_file) do
        ProformaXML::TaskFile.new(
          id: 'ms-file',
          content: 'content',
          filename: 'filename.txt',
          used_by_grader: 'used_by_grader',
          visible: 'yes',
          usage_by_lms: 'display',
          binary: false
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
          ProformaXML::ModelSolution.new(
            id: 'ms-id-2',
            files: ms_files2
          )
        end
        let(:ms_files2) { [ms_file2] }
        let(:ms_file2) do
          ProformaXML::TaskFile.new(
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
        ProformaXML::Test.new(
          id: 'test-id',
          title: 'title',
          description: 'description',
          test_type: 'test_type',
          files: test_files,
          meta_data: {
            'test-meta-data' => {
              '@@order' => %w[CodeOcean:test-file],
              '@xmlns' => {'CodeOcean' => 'codeocean.openhpi.de'},
              'CodeOcean:test-file' => {
                'CodeOcean:test_file_id' =>
                {
                  '@@order' => %w[CodeOcean:feedback-message CodeOcean:weight CodeOcean:hidden-feedback],
                '@name' => 'test_file_name',
                'CodeOcean:feedback-message' => {'$1' => 'feedback-message', '@@order' => ['$1']},
                'CodeOcean:weight' => {'$1' => '0.7', '@@order' => ['$1']},
                'CodeOcean:hidden-feedback' => {'$1' => 'true', '@@order' => ['$1']},
                },
              },
            },
          }
        )
      end

      let(:test_files) { [test_file] }
      let(:test_file) do
        ProformaXML::TaskFile.new(
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
          weight: 0.7,
          content: 'testfile-content',
          name: 'testfile',
          role: 'teacher_defined_test',
          hidden: true,
          read_only: true,
          hidden_feedback: true,
          file_type: be_a(FileType).and(have_attributes(file_extension: '.txt'))
        )
      end

      context 'when test file is a teacher_defined_linter' do
        let(:meta_data) do
          {
            '@@order' => ['meta-data'], 'meta-data' => {
              '@@order' => %w[CodeOcean:files],
            '@xmlns' => {'CodeOcean' => 'codeocean.openhpi.de'},
            'CodeOcean:files' => files_meta_data,
            }
          }
        end
        let(:files_meta_data) do
          {
            '@@order' => ["CodeOcean:CO-#{test_file.id}"],
            "CodeOcean:CO-#{test_file.id}" => {
              '@@order' => ['CodeOcean:role'],
              'CodeOcean:role' => {'$1' => 'teacher_defined_linter', '@@order' => ['$1']},
            },
          }
        end

        it 'creates an exercise with a test' do
          expect(convert_to_exercise_service.files.select {|file| file.role == 'teacher_defined_linter' }).to have(1).item
        end
      end

      context 'when task has multiple tests' do
        let(:tests) { [test, test2] }
        let(:test2) do
          ProformaXML::Test.new(files: test_files2)
        end
        let(:test_files2) { [test_file2] }
        let(:test_file2) do
          ProformaXML::TaskFile.new(
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
        create(
          :files,
          title: 'exercise-title',
          description: 'exercise-description'
        )
      end

      before { exercise.reload }

      it 'assigns all values to given exercise' do
        convert_to_exercise_service.save
        expect(exercise.reload).to have_attributes(
          id: exercise.id,
          title: exercise.title,
          description: exercise.description,
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
          ProformaXML::TaskFile.new(
            id: 'id',
            content: 'content',
            filename: 'filename.txt',
            used_by_grader: 'used_by_grader',
            visible: 'yes',
            usage_by_lms: 'display',
            binary: false
          )
        end
        let(:tests) { [test] }
        let(:test) do
          ProformaXML::Test.new(
            id: 'test-id',
            title: 'title',
            description: 'description',
            test_type: 'test_type',
            files: test_files
          )
        end
        let(:test_files) { [test_file] }
        let(:test_file) do
          ProformaXML::TaskFile.new(
            id: 'test-file-id',
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
          ProformaXML::ModelSolution.new(
            id: 'ms-id',
            files: ms_files
          )
        end
        let(:ms_files) { [ms_file] }
        let(:ms_file) do
          ProformaXML::TaskFile.new(
            id: 'ms-file-id',
            content: 'ms-content',
            filename: 'filename.txt',
            used_by_grader: 'used_by_grader',
            visible: 'delayed',
            usage_by_lms: 'display',
            binary: false,
            internal_description: 'reference_implementation'
          )
        end

        it 'assigns all values to given exercise' do
          expect(convert_to_exercise_service).to have_attributes(
            id: exercise.id,
            files: have(3).items
              .and(include(have_attributes(content: 'ms-content', role: 'reference_implementation', hidden: true)))
              .and(include(have_attributes(content: 'content', role: 'regular_file', hidden: false)))
              .and(include(have_attributes(content: 'testfile-content', role: 'teacher_defined_test', hidden: true)))
          )
        end

        context 'when the files with correct xml_id_paths already exist' do
          let(:exercise) do
            create(:dummy,
              unpublished: true,
              files: co_files,
              title: 'exercise-title',
              description: 'exercise-description')
          end
          let(:co_files) do
            [build(:file, xml_id_path: ['id'], role: 'regular_file'),
             build(:file, xml_id_path: %w[ms-id ms-file-id], role: 'reference_implementation'),
             build(:test_file, xml_id_path: %w[test-id test-file-id])]
          end

          it 'reuses existing file' do
            convert_to_exercise_service
            exercise.save!
            expect(exercise.reload.files).to match_array(co_files)
          end

          context 'when files are move around' do
            let(:files) { [test_file] }
            let(:test_files) { [ms_file] }
            let(:ms_files) { [file] }

            it 'reuses existing file' do
              convert_to_exercise_service
              exercise.save!
              expect(exercise.reload.files).to match_array(co_files)
            end
          end

          context 'when some files are removed' do
            let(:test_files) { [] }
            let(:ms_files) { [] }

            it 'removes files from exercise' do
              convert_to_exercise_service
              exercise.save!
              expect(exercise.reload.files.count).to be 1
            end

            it 'destroys removed files' do
              expect { convert_to_exercise_service }.to change(CodeOcean::File, :count).by(-2)
            end
          end

          context 'when all files are removed' do
            let(:files) { [] }
            let(:test_files) { [] }
            let(:ms_files) { [] }

            it 'removes files from exercise' do
              convert_to_exercise_service
              exercise.save!
              expect(exercise.reload.files).to be_empty
            end

            it 'destroys removed files' do
              expect { convert_to_exercise_service }.to change(CodeOcean::File, :count).by(-3)
            end

            context 'when the import errors after the file deletion' do
              before { allow(exercise).to receive(:assign_attributes).and_raise(StandardError) }

              it 'rolls back deletion of files' do
                expect { convert_to_exercise_service }.to raise_error(StandardError).and(avoid_change(CodeOcean::File, :count))
              end
            end
          end
        end
      end
    end
  end
end
