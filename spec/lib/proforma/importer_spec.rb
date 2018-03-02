require 'rails_helper'

describe Proforma::Importer do

  let (:importer) {described_class.new}
  let (:generator) {Proforma::XmlGenerator.new}
  let(:exercise) {FactoryBot.create(:codeharbor_test)}
  let(:xml) { generator.generate_xml(exercise) }
  let(:user) {FactoryBot.create(:teacher)}


  describe 'import exercise' do

    let(:imported_exercise) {
      imported_exercise = Exercise.new
      imported_exercise = importer.from_proforma_xml(imported_exercise, xml)
      imported_exercise.user = user
      imported_exercise.save
      imported_exercise
    }

    it 'imports valid exercise' do
      expect(imported_exercise).to be_valid
    end

    it 'has valid title' do
      expect(imported_exercise.title).to eq exercise.title
    end

    it 'has valid description' do
      expect(imported_exercise.description).to eq exercise.description
    end

    it 'has valid execution environment' do
      expect(imported_exercise.execution_environment_id).to eq exercise.execution_environment_id
    end

    describe 'files' do
      it 'has valid main file' do
        file = exercise.files.find_by(role: 'main_file')
        imported_file = imported_exercise.files.find_by(role: 'main_file')
        expect(imported_file).not_to be_nil
        expect(file.name).to eq imported_file.name
        expect(file.file_type_id).to eq imported_file.file_type_id
        expect(file.content).to eq imported_file.content
      end

      it 'has valid regular file' do
        file = exercise.files.find_by(role: 'regular_file')
        imported_file = imported_exercise.files.find_by(name: 'explanation')
        expect(imported_file).not_to be_nil
        expect(file.name).to eq imported_file.name
        expect(file.file_type_id).to eq imported_file.file_type_id
        expect(file.content).to eq imported_file.content
      end

      it 'has valid solution file' do
        file = exercise.files.find_by(role: 'reference_implementation')
        imported_file = imported_exercise.files.find_by(role: 'reference_implementation')
        expect(imported_file).not_to be_nil
        expect(file.name).to eq imported_file.name
        expect(file.file_type_id).to eq imported_file.file_type_id
        expect(file.content).to eq imported_file.content
      end

      it 'does not have a user defined test-file' do
        imported_file = imported_exercise.files.find_by(role: 'user_defined_test')
        expect(imported_file).to be_nil
      end

      it 'has valid test file' do
        file = exercise.files.find_by(role: 'teacher_defined_test')
        imported_file = imported_exercise.files.find_by(role: 'teacher_defined_test')
        expect(imported_file).not_to be_nil
        expect(file.name).to eq imported_file.name
        expect(file.file_type_id).to eq imported_file.file_type_id
        expect(file.content).to eq imported_file.content
      end
    end
  end
end