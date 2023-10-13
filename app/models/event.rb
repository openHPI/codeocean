# frozen_string_literal: true

class Event < ApplicationRecord
  include Creation
  belongs_to :exercise
  belongs_to :file, class_name: 'CodeOcean::File', optional: true
  belongs_to :study_group, optional: true
  belongs_to :programming_group, optional: true

  validates :category, presence: true

  # We allow an event to be stored without data for pair programming (pp).
  # This is useful if the category (together with the user and exercise) is already enough.
  validates :data, presence: true, if: -> { %w[pp_start_chat pp_invalid_partners pp_work_alone].exclude?(category) }

  before_validation :data_presence

  def data_presence
    self.data = data.presence
  end
end
