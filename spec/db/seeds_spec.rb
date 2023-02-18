# frozen_string_literal: true

require 'rails_helper'

describe 'seeds' do
  subject(:seed) { Rake::Task['db:seed'].invoke }

  before do
    CodeOcean::Application.load_tasks

    # We want to execute the seeds for the dev environment against the test database
    # rubocop:disable Rails/Inquiry
    allow(Rails).to receive(:env) { 'development'.inquiry }
    # rubocop:enable Rails/Inquiry
    allow(ActiveRecord::Base).to receive(:establish_connection).and_call_original
    allow(ActiveRecord::Base).to receive(:establish_connection).with(:development) {
      ActiveRecord::Base.establish_connection(:test)
    }
    allow_any_instance_of(ExecutionEnvironment).to receive(:working_docker_image?).and_return true
    allow_any_instance_of(ExecutionEnvironment).to receive(:sync_runner_environment).and_return true

    # Disable confirmation message while testing seeds
    allow(HighLine).to receive(:say)
  end

  describe 'execute db:seed', cleaning_strategy: :truncation do
    it 'collects the test results' do
      expect { seed }.not_to raise_error
    end
  end
end
