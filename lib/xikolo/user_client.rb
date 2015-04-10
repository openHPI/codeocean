class Xikolo::UserClient
  def self.get(user_id)
    user = Xikolo::Client.get_user(user_id)

    # return default values if user is not found or if there is a server issue:
    if user
      return {display_name: user['first_name'], user_visual: user['user_visual'], language: user['language']}
    else
      return {display_name: "Name" + user_id, user_visual: ActionController::Base.helpers.image_path('default.png'), language: "DE"}
    end
  end
end