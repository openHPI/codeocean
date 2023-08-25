# frozen_string_literal: true

class PairProgramming23Study
  ENABLE = ENV.fetch('PAIR_PROGRAMMING_23_STUDY', nil) == 'true'

  def self.participate?
    # TODO: Decide which users are in the study
    ENABLE
  end
end
