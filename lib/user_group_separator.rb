class UserGroupSeparator

  # seperates user into 30% no intervention, 30% break intervention, 40% rfc intervention
  def self.getInterventionGroup(user)
    lastDigitId = user.id % 10
    if lastDigitId < 3 # 0,1,2
      :no_intervention
    elsif lastDigitId < 6 # 3,4,5
      :break_intervention
    else # 6,7,8,9
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

end