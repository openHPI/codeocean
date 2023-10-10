# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Factories' do
  it 'are all valid', permitted_execution_time: 30 do
    expect { FactoryBot.lint }.not_to raise_error
  end
end
