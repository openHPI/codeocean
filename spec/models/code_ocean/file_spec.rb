# frozen_string_literal: true

require 'rails_helper'

describe CodeOcean::File do
  let(:file) { described_class.create.tap {|file| file.update(content: nil, hidden: nil, read_only: nil) } }

  it 'validates the presence of a file type' do
    expect(file.errors[:file_type]).to be_present
  end

  it 'validates the presence of the hidden flag' do
    expect(file.errors[:hidden]).to be_present
    file.update(hidden: false)
    expect(file.errors[:hidden]).to be_blank
  end

  it 'validates the presence of a name' do
    expect(file.errors[:name]).to be_present
  end

  it 'validates the presence of the read-only flag' do
    expect(file.errors[:read_only]).to be_present
    file.update(read_only: false)
    expect(file.errors[:read_only]).to be_blank
  end

  context 'with a teacher-defined test' do
    before { file.update(role: 'teacher_defined_test') }

    it 'validates the presence of a feedback message' do
      expect(file.errors[:feedback_message]).to be_present
    end

    it 'validates the numericality of a weight' do
      file.update(weight: 'heavy')
      expect(file.errors[:weight]).to be_present
    end

    it 'validates the presence of a weight' do
      expect(file.errors[:weight]).to be_present
    end
  end

  context 'with another file type' do
    before { file.update(role: 'regular_file') }

    it 'validates the absence of a feedback message' do
      file.update(feedback_message: 'Your solution is not correct yet.')
      expect(file.errors[:feedback_message]).to be_present
    end

    it 'validates the absence of a weight' do
      allow(file).to receive(:clear_weight)
      file.update(weight: 1)
      expect(file.errors[:weight]).to be_present
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
        file.update_column(:native_file, '../../../../secrets.yml') # rubocop:disable Rails/SkipsModelValidations
        file.reload
      end

      it 'does not read the native file' do
        expect(file.read).not_to be_present
      end
    end

    context 'when a symlink is used' do
      let(:fake_upload_location) { File.join(CarrierWave::Uploader::Base.new.root, 'uploads', 'files', 'secrets.yml') }

      before do
        FileUtils.mkdir_p(File.dirname(fake_upload_location))
        FileUtils.touch Rails.root.join('config/secrets.yml')
        File.symlink Rails.root.join('config/secrets.yml'), fake_upload_location
        file.update_column(:native_file, '../secrets.yml') # rubocop:disable Rails/SkipsModelValidations
        file.reload
      end

      after { File.delete(fake_upload_location) }

      it 'does not read the native file' do
        expect(file.read).not_to be_present
      end
    end
  end
end
