# frozen_string_literal: true

module Prometheus
  module Record
    extend ActiveSupport::Concern

    included do
      after_create_commit :create_notification
      after_destroy_commit :destroy_notification
      after_update_commit :update_notification
    end

    private

    def create_notification
      Prometheus::Controller.create_notification self
    end

    def destroy_notification
      Prometheus::Controller.destroy_notification self
    end

    def update_notification
      Prometheus::Controller.update_notification self
    end
  end
end
