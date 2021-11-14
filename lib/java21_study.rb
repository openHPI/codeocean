# frozen_string_literal: true

class Java21Study
  def self.get_for(exercise)
    java21_collection = ExerciseCollection.find_by(name: 'java2021', id: 13)

    exercise.exercise_collections.include? java21_collection
  end

  def self.show_tips_intervention?(user, exercise)
    java21_exercise = get_for(exercise)
    return false unless java21_exercise # Exercise is not part of the experiment

    user_group = UserGroupSeparator.get_intervention_group(user.id)
    user_group == :show_tips_intervention
  end

  def self.show_break_intervention?(user, exercise)
    java21_exercise = get_for(exercise)
    return false unless java21_exercise # Exercise is not part of the experiment

    user_group = UserGroupSeparator.get_intervention_group(user.id)
    user_group == :show_break_intervention
  end

  def self.allow_redirect_to_community_solution?(user, exercise)
    java21_exercise = get_for(exercise)
    return false unless java21_exercise # Exercise is not part of the experiment

    user_group = UserGroupSeparator.get_community_solution_group(user.id)
    user_group == :show_community_solution
  end
end
