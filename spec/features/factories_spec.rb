require 'rails_helper'

describe 'Factories' do
  it 'are all valid', permitted_execution_time: 30 do
    expect { FactoryGirl.lint }.not_to raise_error
  end
end
