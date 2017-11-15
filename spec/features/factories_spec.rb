require 'rails_helper'

describe 'Factories' do
  it 'are all valid', docker: true, permitted_execution_time: 30 do
    expect { FactoryBot.lint }.not_to raise_error
  end
end
