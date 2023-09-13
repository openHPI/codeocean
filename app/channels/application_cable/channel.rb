# frozen_string_literal: true

module ApplicationCable
  class Channel < ActionCable::Channel::Base
    def ensure_confirmation_sent
      # Currently, we are required to overwrite this ActionCable method.
      # Once called and the subscription confirmation is sent, we call the custom callback.
      # See https://github.com/rails/rails/issues/25333.
      super
      @streaming_confirmation_callback.call if subscription_confirmation_sent? && @streaming_confirmation_callback.present?
    end

    def send_after_streaming_confirmed(&block)
      if connection.server.config.pubsub_adapter.to_s == 'ActionCable::SubscriptionAdapter::Async'
        # We can send messages immediately if we're using the async adapter.
        yield block
      else
        # We need to wait for the subscription to be confirmed before we can send further messages.
        # Otherwise, the client might not be ready to receive them.
        @streaming_confirmation_callback = block
      end
    end
  end
end
