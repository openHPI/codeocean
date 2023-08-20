# frozen_string_literal: true

# TODO: reference to lti_param_model
class RemoteEvaluationMapping < ApplicationRecord
  include Creation
  before_create :generate_token, unless: :validation_token?
  belongs_to :exercise
  belongs_to :study_group, optional: true

  def generate_token
    self.validation_token = SecureRandom.urlsafe_base64
  end
end
