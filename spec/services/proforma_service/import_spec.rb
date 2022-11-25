# frozen_string_literal: true

require 'rails_helper'

describe ProformaService::Import do
  describe '.new' do
    subject(:import_service) { described_class.new(zip:, user:) }

    let(:zip) { Tempfile.new('proforma_test_zip_file') }
    let(:user) { build(:teacher) }

    it 'assigns zip' do
      expect(import_service.instance_variable_get(:@zip)).to be zip
    end

    it 'assigns user' do
      expect(import_service.instance_variable_get(:@user)).to be user
    end
  end

  describe '#execute' do
    subject(:import_service) { described_class.call(zip: zip_file, user: import_user) }

    let(:user) { create(:teacher) }
    let(:import_user) { user }
    let(:zip_file) { Tempfile.new('proforma_test_zip_file', encoding: 'ascii-8bit') }
    let(:exercise) do
      create(:dummy,
        instructions: 'instruction',
        execution_environment:,
        files: files + tests,
        hide_file_tree:  true,
        allow_file_creation: false,
        allow_auto_completion: true,
        expected_difficulty: 7,
        uuid:,
        user:)
    end

    let(:uuid) { nil }
    let(:execution_environment) { build(:java) }
    let(:files) { [] }
    let(:tests) { [] }
    let(:exporter) { ProformaService::ExportTask.call(exercise: exercise.reload).string }

    before do
      zip_file.write(exporter)
      zip_file.rewind
    end

    it { is_expected.to be_an_equal_exercise_as exercise }

    it 'sets the correct user as owner of the exercise' do
      expect(import_service.user).to be user
    end

    it 'sets the uuid' do
      expect(import_service.uuid).not_to be_blank
    end

    context 'when no exercise exists' do
      before { exercise.destroy }

      it { is_expected.to be_valid }

      it 'sets the correct user as owner of the exercise' do
        expect(import_service.user).to be user
      end

      it 'sets the uuid' do
        expect(import_service.uuid).not_to be_blank
      end

      context 'when task has a uuid' do
        let(:uuid) { SecureRandom.uuid }

        it 'sets the uuid' do
          expect(import_service.uuid).to eql uuid
        end
      end
    end

    context 'when exercise has a mainfile' do
      let(:files) { [file] }
      let(:file) { build(:file) }

      it { is_expected.to be_an_equal_exercise_as exercise }

      context 'when the mainfile is very large' do
        let(:file) { build(:file, content: 'test' * (10**5)) }

        it { is_expected.to be_an_equal_exercise_as exercise }
      end
    end

    context 'when exercise has a regular file' do
      let(:files) { [file] }
      let(:file) { build(:file, role: 'regular_file') }

      it { is_expected.to be_an_equal_exercise_as exercise }

      context 'when file has an attachment' do
        let(:file) { build(:file, :image, role: 'regular_file') }

        it { is_expected.to be_an_equal_exercise_as exercise }
      end
    end

    context 'when exercise has a file with role reference implementation' do
      let(:files) { [file] }
      let(:file) { build(:file, role: 'reference_implementation', read_only: true) }

      it { is_expected.to be_an_equal_exercise_as exercise }
    end

    context 'when exercise has multiple files with role reference implementation' do
      let(:files) { build_list(:file, 2, role: 'reference_implementation', read_only: true) }

      it { is_expected.to be_an_equal_exercise_as exercise }
    end

    context 'when exercise has a test' do
      let(:tests) { [test] }
      let(:test) { build(:test_file) }

      it { is_expected.to be_an_equal_exercise_as exercise }
    end

    context 'when exercise has multiple tests' do
      let(:tests) { build_list(:test_file, 2) }

      it { is_expected.to be_an_equal_exercise_as exercise }
    end

    context 'when task in zip has a different uuid' do
      let(:uuid) { SecureRandom.uuid }
      let(:new_uuid) { SecureRandom.uuid }
      let(:imported_exercise) { import_service }

      before do
        exercise.update(uuid: new_uuid)
        imported_exercise.save!
      end

      it 'creates a new Exercise' do
        expect(import_service.id).not_to be exercise.id
      end
    end

    context 'when task in zip has the same uuid and nothing has changed' do
      let(:uuid) { SecureRandom.uuid }
      let(:imported_exercise) { import_service }

      it 'updates the old Exercise' do
        imported_exercise.save!
        expect(imported_exercise.id).to be exercise.id
      end

      context 'when another user imports the exercise' do
        let(:import_user) { create(:teacher) }

        it 'raises a proforma error' do
          expect { imported_exercise.save! }.to raise_error Proforma::ExerciseNotOwned
        end
      end
    end
  end
end
