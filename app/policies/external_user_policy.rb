class ExternalUserPolicy < AdminOnlyPolicy
  def statistics?
    admin? || author? || team_member?
  end
end
