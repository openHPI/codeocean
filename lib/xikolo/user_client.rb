class Xikolo::UserClient
  def self.get(user_id)
    user = Xikolo::Client.get_user(user_id)

    # return default values if user is not found or if there is a server issue:
    if user
      name = user.dig('data', 'attributes', 'name') || "User "  + user_id
      user_visual = user.dig('data', 'attributes', 'avatar_url') || ActionController::Base.helpers.image_path('default.png')
      language = user.dig('data', 'attributes', 'language') || "DE"
      return {display_name: name, user_visual: user_visual, language: language}
    else
      return {display_name: "User " + user_id, user_visual: ActionController::Base.helpers.image_path('default.png'), language: "DE"}
    end
  end
end