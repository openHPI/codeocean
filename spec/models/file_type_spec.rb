# frozen_string_literal: true

require 'rails_helper'

describe FileType do
  let(:file_type) { described_class.create.tap {|file_type| file_type.update(binary: nil, executable: nil, renderable: nil) } }

  it 'validates the presence of the binary flag' do
    expect(file_type.errors[:binary]).to be_present
    file_type.update(binary: false)
    expect(file_type.errors[:binary]).to be_blank
  end

  context 'when binary' do
    before { file_type.update(binary: true) }

    it 'does not validate the presence of an editor mode' do
      expect(file_type.errors[:editor_mode]).not_to be_present
    end

    it 'does not validate the presence of an indent size' do
      expect(file_type.errors[:indent_size]).not_to be_present
    end
  end

  context 'when not binary' do
    before { file_type.update(binary: false) }

    it 'validates the presence of an editor mode' do
      expect(file_type.errors[:editor_mode]).to be_present
    end

    it 'validates the presence of an indent size' do
      expect(file_type.errors[:indent_size]).to be_present
    end
  end

  it 'validates the presence of the executable flag' do
    expect(file_type.errors[:executable]).to be_present
    file_type.update(executable: false)
    expect(file_type.errors[:executable]).to be_blank
  end

  it 'validates the presence of a name' do
    expect(file_type.errors[:name]).to be_present
  end

  it 'validates the presence of the renderable flag' do
    expect(file_type.errors[:renderable]).to be_present
    file_type.update(renderable: false)
    expect(file_type.errors[:renderable]).to be_blank
  end

  it 'validates the presence of a user' do
    expect(file_type.errors[:user]).to be_present
  end

  it 'validates the presence of the file_extension' do
    expect(file_type.errors[:file_extension]).to be_present
    file_type.update(file_extension: '')
    expect(file_type.errors[:file_extension]).to be_blank
  end
end
