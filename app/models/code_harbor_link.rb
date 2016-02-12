class CodeHarborLink < ActiveRecord::Base
  validates :oauth2token, presence: true
  validates :user_id, presence: true

  belongs_to :internal_user, foreign_key: :user_id
  alias_method :user, :internal_user
  alias_method :user=, :internal_user=

  def to_s
    oauth2token
  end

end
