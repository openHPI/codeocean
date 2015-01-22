require 'rails_helper'

describe Hint do
  let(:user) { Hint.create }

  it 'validates the presence of an execution environment' do
    expect(user.errors[:execution_environment_id]).to be_present
  end

  it 'validates the presence of a locale' do
    expect(user.errors[:locale]).to be_present
  end

  it 'validates the presence of a message' do
    expect(user.errors[:message]).to be_present
  end

  it 'validates the presence of a name' do
    expect(user.errors[:name]).to be_present
  end

  it 'validates the presence of a regular expression' do
    expect(user.errors[:regular_expression]).to be_present
  end
end
