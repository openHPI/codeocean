# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CodeOcean::File do
  let(:file) do
    described_class.new.tap do |file|
      file.assign_attributes(content: nil, hidden: nil, read_only: nil)
      file.validate
    end
  end

  it 'validates the presence of a file type' do
    expect(file.errors[:file_type]).to be_present
  end

  it 'validates the presence of the hidden flag' do
    expect(file.errors[:hidden]).to be_present
    file.hidden = false
    file.validate
    expect(file.errors[:hidden]).to be_blank
  end

  it 'validates the presence of a name' do
    expect(file.errors[:name]).to be_present
  end

  it 'validates the presence of the read-only flag' do
    expect(file.errors[:read_only]).to be_present
    file.read_only = false
    file.validate
    expect(file.errors[:read_only]).to be_blank
  end

  context 'with a teacher-defined test' do
    before do
      file.role = 'teacher_defined_test'
      file.validate
    end

    it 'validates the presence of a feedback message' do
      expect(file.errors[:feedback_message]).to be_present
    end

    it 'validates the numericality of a weight' do
      file.weight = 'heavy'
      file.validate
      expect(file.errors[:weight]).to be_present
    end

    it 'validates the presence of a weight' do
      expect(file.errors[:weight]).to be_present
    end
  end

  context 'with another file type' do
    before do
      file.role = 'regular_file'
    end

    it 'removes the feedback message' do
      file.feedback_message = 'Your solution is not correct yet.'

      expect { file.validate }
        .to change(file, :feedback_message).to('')
    end

    it 'validates the absence of a weight' do
      allow(file).to receive(:clear_weight)
      file.weight = 1
      file.validate
      expect(file.errors[:weight]).to be_present
    end
  end

  context 'with xml_id_path' do
    let(:exercise) { create(:dummy) }
    let(:file) { build(:file, context: file_context, xml_id_path: xml_id_path) }
    let(:file_context) { exercise }
    let(:xml_id_path) { ['abcde'] }

    before do
      create(:file, context: exercise, xml_id_path: ['abcde'])
      file.validate
    end

    it 'has an error for xml_id_path' do
      expect(file.errors[:xml_id_path]).to be_present
    end

    context 'when second file has a different exercise' do
      let(:file_context) { create(:dummy) }

      it 'has no error for xml_id_path' do
        expect(file.errors[:xml_id_path]).not_to be_present
      end
    end

    context 'when second file has a different xml_id_path' do
      let(:xml_id_path) { ['foobar'] }

      it 'has no error for xml_id_path' do
        expect(file.errors[:xml_id_path]).not_to be_present
      end
    end

    context 'when file_context is not Exercise' do
      let(:file_context) { create(:submission) }

      it 'has an error for xml_id_path' do
        expect(file.errors[:xml_id_path]).to be_present
      end
    end
  end

  context 'with a native file' do
    let(:file) { create(:file, :image) }

    after { file.native_file.remove! }

    context 'when the path has not been modified' do
      it 'reads the native file' do
        expect(file.read).to be_present
      end
    end

    context 'when the path has been modified' do
      before do
        file.update_column(:native_file, '../../../../database.yml') # rubocop:disable Rails/SkipsModelValidations
        file.reload
      end

      it 'does not read the native file' do
        expect(file.read).not_to be_present
      end
    end

    context 'when a symlink is used' do
      let(:fake_upload_location) { File.join(CarrierWave::Uploader::Base.new.root, 'uploads', 'files', 'database.yml') }

      before do
        FileUtils.mkdir_p(File.dirname(fake_upload_location))
        FileUtils.touch Rails.root.join('config/database.yml')
        File.symlink Rails.root.join('config/database.yml'), fake_upload_location
        file.update_column(:native_file, '../database.yml') # rubocop:disable Rails/SkipsModelValidations
        file.reload
      end

      after { File.delete(fake_upload_location) }

      it 'does not read the native file' do
        expect(file.read).not_to be_present
      end
    end
  end
end
