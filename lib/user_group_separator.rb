# frozen_string_literal: true

class UserGroupSeparator

  # Different user groups for Python20 course based on last digit of the user_id
  # 0: show_tips && no_linter
  # 1: no_tips && show_linter
  # 2: show_tips && show_linter
  # 3: no_tips && no_linter

  # separates user into 50% no tips, 50% with tips
  def self.get_tips_group(user_id)
    user_group = user_id % 4 # => 0, 1, 2, 3
    if [0, 2].include?(user_group)
      :show_tips
    else # [1, 3].include?(user_group)
      :no_tips
    end
  end

  # separates user into 50% with linter, 50% without linter
  def self.get_linter_group(user_id)
    user_group = user_id % 4 # => 0, 1, 2, 3
    if [1, 2].include?(user_group)
      :show_linter
    else # [0, 3].include?(user_group)
      :no_linter
    end
  end
end
