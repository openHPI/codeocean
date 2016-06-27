class ExternalUser < ActiveRecord::Base
  include User

  validates :consumer_id, presence: true
  validates :external_id, presence: true

  def displayname
    result = name
    Rails.cache.fetch("#{cache_key}/displayname", expires_in: 12.hours) do
      if(consumer.name == 'openHPI')
        result = Xikolo::UserClient.get(external_id.to_s)[:display_name]
      end
    end
    result
  end

end
