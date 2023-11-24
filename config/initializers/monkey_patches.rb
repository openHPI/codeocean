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

# Required until Rails 7.1 is officially supported.
# See https://github.com/mnemosyne-mon/mnemosyne-ruby/pull/70
module Mnemosyne
  class Trace
    def attach_error(error)
      case error
        when ActionDispatch::ExceptionWrapper
          @errors << Error.new(error.exception)
        when Exception
          @errors << Error.new(error)
        when String
          @errors << Error.new(RuntimeError.new(error))
        else
          raise ArgumentError.new "Invalid error type: #{error.inspect}"
      end
    end
  end
end
