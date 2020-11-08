# frozen_string_literal: true

class Python20CourseWeek

  def self.get_for(exercise)
    case exercise.title
    when /Python20 Aufgabe 1/
      1
    when /Python20 Aufgabe 2/
      2
    when /Python20 Aufgabe 3.1/
      nil # Explicitly enable everything (linter + tips if available)!
    when /Python20 Aufgabe 3.2/
      3
    when /Python20 Aufgabe 3.3/
      3
    when /Python20 Aufgabe 3.4/
      3
    when /Python20 Aufgabe 4/
      4
    when /Python20 Snake/
      4
    else
      # Not part of the Python20 course
      nil
    end
  end

  def self.show_tips?(exercise, user_id)
    week = get_for(exercise)
    return true if week.nil? # Exercise is not part of the experiment

    user_group = UserGroupSeparator.get_tips_group(user_id)
    [1, 2].include?(week) && user_group == :show_tips
  end

  def self.show_linter?(exercise, user_id)
    week = get_for(exercise)
    return true if week.nil? # Exercise is not part of the experiment

    user_group = UserGroupSeparator.get_linter_group(user_id)
    [3].include?(week) && user_group == :show_linter
  end
end
