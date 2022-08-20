# frozen_string_literal: true

class TestrunExecutionEnvironment < ApplicationRecord
  belongs_to :testrun
  belongs_to :execution_environment
end
