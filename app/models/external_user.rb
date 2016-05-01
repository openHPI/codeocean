class ExternalUser < ActiveRecord::Base
  include User

  validates :consumer_id, presence: true
  validates :external_id, presence: true

  def displayname
    result = name
    if(consumer.name == 'openHPI')
      result = Xikolo::UserClient.get(external_id.to_s)[:display_name]
    end
    result
  end

end
