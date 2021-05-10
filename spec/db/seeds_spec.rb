# frozen_string_literal: true

require 'rails_helper'

describe 'seeds' do
  subject(:seed) { Rake::Task['db:seed'].invoke }

  before do
    CodeOcean::Application.load_tasks

    # We want to execute the seeds for the dev environment against the test database
    allow(Rails).to receive(:env) { 'development'.inquiry }
    allow(ActiveRecord::Base).to receive(:establish_connection).and_call_original
    allow(ActiveRecord::Base).to receive(:establish_connection).with(:development) {
      ActiveRecord::Base.establish_connection(:test)
    }
  end

  describe 'execute db:seed' do
    it 'collects the test results' do
      expect { seed }.not_to raise_error
    end
  end
end
