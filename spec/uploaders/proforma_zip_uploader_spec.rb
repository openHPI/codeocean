# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProformaZipUploader, type: :uploader do
  subject(:uploader) { described_class.new }

  let(:file) { Rails.root.join('spec/fixtures/files/proforma_import/testfile.zip').open('r') }

  describe '#filename' do
    before do
      uploader.cache!(file)
    end

    after do
      uploader.remove!
    end

    it 'generates a unique filename using SecureRandom.uuid' do
      expect(uploader.filename).to match(/\b[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\b/)
    end
  end
end
