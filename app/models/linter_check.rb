# frozen_string_literal: true

class LinterCheck < ApplicationRecord
  has_many :linter_check_runs
end
