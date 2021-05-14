# frozen_string_literal: true

require './exercise'

describe '#write_to_file' do
  before(:each) do
    @file_content = File.new(SOURCE_FILENAME, 'r').read
    write_to_file
  end

  it 'preserves the source file' do
    expect(File.exist?(SOURCE_FILENAME)).to be true
    expect(File.new(SOURCE_FILENAME, 'r').read).to eq(@file_content)
  end

  it 'creates the target file' do
    expect(File.exist?(TARGET_FILENAME)).to be true
  end

  it 'copies the file content' do
    expect(File.new(TARGET_FILENAME, 'r').read).to eq(@file_content)
  end
end
