# frozen_string_literal: true

class PairProgramming23Study
  ENABLE = ENV.fetch('PAIR_PROGRAMMING_23_STUDY', nil) == 'true'
  STUDY_GROUP_IDS = [368, 451].freeze
  # All easy tasks of the first week to be solved by the participants on their own
  EXCLUDED_EXERCISE_IDS = [636, 647, 648, 649, 637, 638, 623, 639, 650, 625, 624, 651, 653, 654, 655, 664, 656].freeze
  # The participants are forced to work in pairs on these tasks
  FORCED_EXERCISE_IDS = [723].freeze

  def self.participate?(user, exercise)
    ENABLE || participate_in_pp?(user, exercise)
  end

  def self.participate_in_pp?(user, exercise)
    return false unless experiment_course?(user.current_study_group_id)
    return false if EXCLUDED_EXERCISE_IDS.include?(exercise.id)
    return true if user.external_user? && fixed_enrolled_users.include?([user.consumer_id.to_s, user.external_id])

    user_group = user.id % 3 # => 0, 1, 2
    case user_group
      when 0, 1
        true
      else # 2
        false
    end
  end

  def self.experiment_course?(study_group_id)
    STUDY_GROUP_IDS.include? study_group_id
  end

  def self.csv
    @csv ||= CSV.read(Rails.root.join('config/pair_programming23_study.csv'), headers: true)
  rescue Errno::ENOENT
    []
  end

  def self.fixed_enrolled_users
    @fixed_enrolled_users ||= csv.map do |row|
      [row['consumer_id'], row['external_id']]
    end
  end
end
