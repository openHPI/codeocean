class CodeHarborLink < ActiveRecord::Base
  validates :oauth2token, presence: true

  def to_s
    oauth2token
  end

end
