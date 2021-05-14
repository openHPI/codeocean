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

    def dump_docker
      authorize(self)
      respond_to do |format|
        format.html { render(json: DockerContainerPool.dump_info) }
        format.json { render(json: DockerContainerPool.dump_info) }
      end
    end
  end
end
