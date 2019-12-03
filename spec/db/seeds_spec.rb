# frozen_string_literal: true

require 'rails_helper'

describe 'seeds' do
  subject(:seed) { Rake::Task['db:seed'].invoke }

  before do
    CodeOcean::Application.load_tasks
    allow(Rails).to receive(:env) { 'development'.inquiry }
  end

  describe 'execute db:seed' do
    it 'collects the test results' do
      expect { seed }.not_to raise_error(StandardError)
    end
  end
end
