# todo: reference to lti_param_model
class RemoteEvaluationMapping < ActiveRecord::Base
  before_create :generate_token, unless: :validation_token?
  belongs_to :exercise
  belongs_to :user

  def generate_token
    self.validation_token = SecureRandom.urlsafe_base64
  end
end