# frozen_string_literal: true

unless Array.respond_to?(:average)
  class Array
    def average
      sum / length if present?
    end
  end
end

module WillPaginate
  module ActionView
    class Bootstrap4LinkRenderer
      def previous_or_next_page(page, text, classname, aria_label = nil)
        tag :li, link(text, page || '#', class: 'page-link', 'aria-label': aria_label), class: [(classname[0..3] if @options[:page_links]), (classname if @options[:page_links]), ('disabled' unless page), 'page-item'].join(' ')
      end
    end
  end
end

# Sorcery is currently overwriting the redirect_back_or_to method, which has been introduced in Rails 7.0+
# See https://github.com/Sorcery/sorcery/issues/296
module Sorcery
  module Controller
    module InstanceMethods
      define_method :sorcery_redirect_back_or_to, instance_method(:redirect_back_or_to)
      remove_method :redirect_back_or_to
    end
  end
end

# Tubesock uses a deprecated method to clear active connections with ActiveRecord.
# Hence, we update the method call to the new method name (including `connection_handler`).
module Tubesock::Hijack
  extend ActiveSupport::Concern

  # First, we need to remove the old `included` definition.
  # Otherwise, we would get an `ActiveSupport::Concern::MultipleIncludedBlocks` exception.
  remove_instance_variable :@_included_block

  included do
    def hijack
      sock = Tubesock.hijack(request.env)
      yield sock
      sock.onclose do
        ActiveRecord::Base.connection_handler.clear_active_connections! if defined? ActiveRecord
      end
      sock.listen
      render plain: nil, status: -1
    end
  end
end
