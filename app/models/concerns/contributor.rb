# frozen_string_literal: true

module Contributor
  extend ActiveSupport::Concern

  included do
    has_many :submissions, as: :contributor
  end
end
