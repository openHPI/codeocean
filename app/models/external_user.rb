class ExternalUser < User

  validates :consumer_id, presence: true
  validates :external_id, presence: true

  def displayname
    result = name
    if(result == nil || result == "")
      result = "User " + id.to_s
    end
    result
  end

end
