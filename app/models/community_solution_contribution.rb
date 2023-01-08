# frozen_string_literal: true

class CommunitySolutionContribution < ApplicationRecord
  include Creation
  include Context

  belongs_to :community_solution
  belongs_to :community_solution_lock

  validates :proposed_changes, inclusion: [true, false]
  validates :timely_contribution, inclusion: [true, false]
  validates :autosave, inclusion: [true, false]
  validates :working_time, presence: true
end
