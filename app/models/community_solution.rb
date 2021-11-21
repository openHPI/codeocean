# frozen_string_literal: true

class CommunitySolution < ApplicationRecord
  belongs_to :exercise
  has_many :community_solution_locks
  has_many :community_solution_contributions
  has_and_belongs_to_many :users, polymorphic: true, through: :community_solution_contributions
  has_many :files, class_name: 'CodeOcean::File', through: :community_solution_contributions

  def to_s
    "Gemeinschaftslösung für #{exercise}"
  end
end
