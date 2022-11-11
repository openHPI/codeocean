# frozen_string_literal: true

require 'prometheus_exporter/client'

module Prometheus
  module Controller
    # TODO: currently active users - as Event
    # TODO: active_in_last_hour
    # TODO: autosaves_per_minute

    class << self
      def initialize_metrics
        return unless CodeOcean::Config.new(:code_ocean).read[:prometheus_exporter][:enabled] && defined?(::Rails::Console).blank?

        register_metrics
        Rails.application.executor.wrap do
          Thread.new do
            initialize_instance_count
            initialize_rfc_metrics
          rescue StandardError => e
            Sentry.capture_exception(e)
          ensure
            ActiveRecord::Base.connection_pool.release_connection
          end
        end
      end

      def register_metrics
        prometheus = PrometheusExporter::Client.default

        @instance_count = prometheus.register(:gauge, :instance_count, help: 'Instance count')
        # counts solved, soft_solved, ongoing
        @rfc_count = prometheus.register(:gauge, :rfc_count, help: 'Count of RfCs in each state')
        # counts commented
        @rfc_commented_count = prometheus.register(:gauge, :rfc_commented_count, help: 'Count of commented RfCs')
      end

      def initialize_instance_count
        ApplicationRecord.descendants.reject(&:abstract_class).each do |each|
          @instance_count.observe(each.count, class: each.name)
        end
      end

      def initialize_rfc_metrics
        # Initialize rfc metric
        @rfc_count.observe(RequestForComment.unsolved.where(full_score_reached: false).count,
          state: RequestForComment::ONGOING)
        @rfc_count.observe(RequestForComment.unsolved.where(full_score_reached: true).count,
          state: RequestForComment::SOFT_SOLVED)
        @rfc_count.observe(RequestForComment.where(solved: true).count,
          state: RequestForComment::SOLVED)

        # count of rfcs with comments
        @rfc_commented_count.observe(RequestForComment.joins(:comments).distinct.count(:id))
      end

      def update_notification(object)
        Rails.logger.debug { "Prometheus metric updated for #{object.class.name}" }

        case object
          when RequestForComment
            update_rfc(object)
        end
      end

      def create_notification(object)
        @instance_count.increment(class: object.class.name)
        Rails.logger.debug { "Prometheus instance count increased for #{object.class.name}" }

        case object
          when RequestForComment
            create_rfc(object)
          when Comment
            create_comment(object)
        end
      end

      def destroy_notification(object)
        @instance_count.decrement(class: object.class.name)
        Rails.logger.debug { "Prometheus instance count decreased for #{object.class.name}" }

        case object
          when Comment
            destroy_comment(object)
        end
      end

      def create_rfc(rfc)
        @rfc_count.increment(state: rfc.current_state)
      end

      def update_rfc(rfc)
        @rfc_count.decrement(state: rfc.old_state)
        # If the metrics are scraped when the execution is exactly at the place of this comment,
        # the old state is already decremented while the new state is not yet incremented and
        # the metric is therefore inconsistent. As this is only a temporarily off by one error
        # in the metric and a solution (e.g. a mutex) would be complex, this is acceptable.
        @rfc_count.increment(state: rfc.current_state)
      end

      def create_comment(comment)
        @rfc_commented_count.increment if comment.only_comment_for_rfc?
      end

      def destroy_comment(comment)
        @rfc_commented_count.decrement unless comment.request_for_comment.comments?
      end
    end
  end
end
