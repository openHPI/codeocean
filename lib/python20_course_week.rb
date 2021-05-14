# frozen_string_literal: true

class Python20CourseWeek
  def self.get_for(exercise)
    case exercise.title
      when /Python20 Aufgabe 1/
        1
      when /Python20 Aufgabe 2/
        2
      when /Python20 Aufgabe 3/
        3
      when /Python20 Aufgabe 4/, /Python20 Snake/
        4
      # else: Not part of the Python20 course
    end
  end

  def self.show_linter?(exercise)
    week = get_for(exercise)
    return true if week.nil? # Exercise is not part of the experiment

    [3, 4].include?(week)
  end
end
