class StatisticsPolicy < AdminOnlyPolicy

  def graphs?
    admin?
  end

end
