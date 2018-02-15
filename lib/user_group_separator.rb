class UserGroupSeparator

  # seperates user into 20% no intervention, 20% break intervention, 60% rfc intervention
  def self.getInterventionGroup(user)
    lastDigitId = user.id % 10
    if lastDigitId < 2 # 0,1
      :no_intervention
    elsif lastDigitId < 4 # 2,3
      :break_intervention
    else # 4,5,6,7,8,9
      :rfc_intervention
    end
  end

  # seperates user into 20% dummy assignment, 20% random assignemnt, 60% recommended assignment
  def self.getProxyExerciseGroup(user)
    lastDigitCreatedAt = user.created_at.to_i % 10
    if lastDigitCreatedAt < 2 # 0,1
      :dummy_assigment
    elsif lastDigitCreatedAt < 4 # 2,3
      :random_assigment
    else # 4,5,6,7,8,9
      :recommended_assignment
    end
  end

  def self.getRequestforCommentGroup(user)
    lastDigitId = user.id % 10
    if lastDigitId < 2 # 0,1
      :hide_rfc
    elsif lastDigitId < 4 # 2,3
      :stale_rfc
    else # 4,5,6,7,8,9
      :show_rfc
    end
  end

end