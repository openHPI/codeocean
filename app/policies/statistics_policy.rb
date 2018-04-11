class StatisticsPolicy < AdminOnlyPolicy

  def graphs?
    admin?
  end

  def user_activity?
    admin?
  end

  def rfc_activity?
    admin?
  end

end
