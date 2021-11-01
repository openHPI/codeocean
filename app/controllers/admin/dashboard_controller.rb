# frozen_string_literal: true

module Admin
  class DashboardController < ApplicationController
    include DashboardHelper

    def policy_class
      DashboardPolicy
    end

    def show
      authorize(self)
      respond_to do |format|
        format.html
        format.json { render(json: dashboard_data) }
      end
    end
  end
end
