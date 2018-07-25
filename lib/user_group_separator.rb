class UserGroupSeparator

  # seperates user into 20% no intervention, 20% break intervention, 60% rfc intervention
  def self.getInterventionGroup(user)
    lastDigitId = user.id % 10
    if lastDigitId < 1 # 0
      :rfc_intervention_stale_rfc
    elsif lastDigitId < 2 # 1
      :break_intervention_stale_rfc
    elsif lastDigitId < 3 # 2
      :no_intervention_stale_rfc
    elsif lastDigitId < 4 # 3
      :no_intervention_hide_rfc
    elsif lastDigitId < 5 # 4
      :break_intervention_show_rfc
    elsif lastDigitId < 6 # 5
      :no_intervention_show_rfc
    else # 6,7,8,9
      :rfc_intervention_show_rfc
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

  def self.getGroupExerciseDescriptionTesting(user)
    groupById = user.id % 4
    if groupById == 0
      :group_a
    elsif groupById == 1
      :group_b
    elsif groupById == 2
      :group_c
    else # 3
      :group_d
    end
  end

end