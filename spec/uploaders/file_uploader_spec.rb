# frozen_string_literal: true

require 'rails_helper'

describe FileUploader do
  let(:file_path) { Rails.root.join('db/seeds/fibonacci/exercise.rb') }
  let(:uploader) { described_class.new(create(:file)) }

  before { uploader.store!(File.open(file_path, 'r')) }

  after { uploader.remove! }

  it 'uses the specified storage directory' do
    expect(uploader.file.path).to start_with(Rails.public_path.join(uploader.store_dir).to_s)
    expect(uploader.file.path).to end_with(file_path.basename.to_s)
  end

  it 'stores the file content' do
    expect(uploader.file.read).to eq(File.read(file_path))
  end
end
