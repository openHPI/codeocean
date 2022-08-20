# frozen_string_literal: true

class UserGroupSeparator
  # Different user groups for the Java21 course based on the user_id
  # 0: show_tips_intervention && show_community_solution
  # 1: show_break_intervention && show_community_solution
  # 2: show_rfc_intervention && show_community_solution
  # 3: show_tips_intervention && no_community_solution
  # 4: show_break_intervention && no_community_solution
  # 5: show_rfc_intervention && no_community_solution

  # separates user into 33% tips interventions, 33% break intervention, 33% rfc intervention
  def self.get_intervention_group(user_id)
    user_group = user_id % 6 # => 0, 1, 2, 3, 4, 5
    case user_group
      when 0, 3
        :show_tips_intervention
      when 1, 4
        :show_break_intervention
      else # 2, 5
        :show_rfc_intervention
    end
  end

  # separates user into 50% with Community Solution, 50% without Community Solution
  def self.get_community_solution_group(user_id)
    user_group = user_id % 6 # => 0, 1, 2, 3, 4, 5
    case user_group
      when 0, 1, 2
        :show_community_solution
      else # 3, 4, 5
        :no_community_solution
    end
  end

  # Different user groups for using AWS lambda functions instead of Nomad based on the user_id
  # This test is independent from any other A/B Test
  def self.get_aws_group(user_id)
    user_group = user_id % 2 # => 0, 1
    case user_group
      when 0
        :no_aws
      else # 1
        :use_aws
    end
  end
end
