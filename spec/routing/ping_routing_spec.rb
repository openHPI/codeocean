# frozen_string_literal: true

require 'rails_helper'

describe PingController, type: :routing do
  context 'with routes to #show' do
    it { expect(get: '/ping').to route_to('ping#index', format: :json) }
  end
end
