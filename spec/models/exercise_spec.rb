require 'rails_helper'

describe Exercise do
  let(:exercise) { Exercise.create.tap { |exercise| exercise.update(public: nil, token: nil) } }

  it 'validates the presence of a description' do
    expect(exercise.errors[:description]).to be_present
  end

  it 'validates the presence of an execution environment' do
    expect(exercise.errors[:execution_environment_id]).to be_present
  end

  it 'validates the presence of the public flag' do
    expect(exercise.errors[:public]).to be_present
  end

  it 'validates the presence of a title' do
    expect(exercise.errors[:title]).to be_present
  end

  it 'validates the presence of a token' do
    expect(exercise.errors[:token]).to be_present
  end

  it 'validates the presence of a user' do
    expect(exercise.errors[:user_id]).to be_present
    expect(exercise.errors[:user_type]).to be_present
  end
end
