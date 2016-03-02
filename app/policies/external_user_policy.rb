class ExternalUserPolicy < AdminOnlyPolicy
  def statistics?
    admin?
  end
end
