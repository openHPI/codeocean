# frozen_string_literal: true

class CommunitySolutionContribution < ApplicationRecord
  include Creation
  include Context

  belongs_to :community_solution
  belongs_to :community_solution_lock

  validates :proposed_changes, boolean_presence: true
  validates :timely_contribution, boolean_presence: true
  validates :autosave, boolean_presence: true
  validates :working_time, presence: true
end
