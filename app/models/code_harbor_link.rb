class CodeHarborLink < ActiveRecord::Base
  validates :oauth2token, presence: true
  validates :user_id, presence: true

  belongs_to :user

  def to_s
    oauth2token
  end

end
