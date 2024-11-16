# frozen_string_literal: true

class Contributor < ApplicationRecord
  self.abstract_class = true

  has_many :anomaly_notifications, as: :contributor, dependent: :destroy
  has_many :user_exercise_interventions, as: :contributor
  has_many :runners, as: :contributor, dependent: :destroy

  has_many :submissions, as: :contributor

  delegate :to_s, to: :displayname

  def learner?
    raise NotImplementedError
  end

  def teacher?
    raise NotImplementedError
  end

  def admin?
    raise NotImplementedError
  end

  def internal_user?
    is_a?(InternalUser)
  end

  def external_user?
    is_a?(ExternalUser)
  end

  def programming_group?
    is_a?(ProgrammingGroup)
  end

  def to_page_context
    {
      id:,
      type: self.class.name,
      consumer: try(:consumer)&.name, # Only a user is associated with a consumer.
      displayname:,
    }
  end
end
