require 'rails_helper'

describe Hint do
  let(:hint) { described_class.create }

  it 'validates the presence of an execution environment' do
    expect(hint.errors[:execution_environment_id]).to be_present
  end

  it 'validates the presence of a locale' do
    expect(hint.errors[:locale]).to be_present
  end

  it 'validates the presence of a message' do
    expect(hint.errors[:message]).to be_present
  end

  it 'validates the presence of a name' do
    expect(hint.errors[:name]).to be_present
  end

  it 'validates the presence of a regular expression' do
    expect(hint.errors[:regular_expression]).to be_present
  end

  describe '.nested_resource?' do
    it 'is true' do
      expect(described_class.nested_resource?).to be true
    end
  end

  describe '#to_s' do
    it "equals the hint's name" do
      expect(hint.to_s).to eq(hint.name)
    end
  end
end
