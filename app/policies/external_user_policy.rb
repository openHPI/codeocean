class ExternalUserPolicy < AdminOnlyPolicy
  def statistics?
    admin?
  end

  def tag_statistics?
    admin?
  end
end
