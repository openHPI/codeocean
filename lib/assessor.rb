# frozen_string_literal: true

class Assessor
  MAXIMUM_SCORE = 1

  def assess(output)
    test_outcome = @testing_framework_adapter.test_outcome(output)
    test_outcome.merge(score: calculate_score(test_outcome))
  rescue StandardError
    {score: 0}
  end

  def calculate_score(test_outcome)
    score = 0.0
    if test_outcome[:passed].to_d != BigDecimal('0.0') && test_outcome[:count].to_d != BigDecimal('0.0')
      score = (test_outcome[:passed].to_f / test_outcome[:count])
      # prevent negative scores
      score = [0.0, score].max
    end
    score
  end
  private :calculate_score

  def initialize(options = {})
    if options[:execution_environment].testing_framework?
      @testing_framework_adapter = options[:execution_environment].testing_framework.constantize.new
    else
      raise Error.new('No testing framework adapter set!')
    end
  end

  def translate_linter(result, locale)
    @testing_framework_adapter.try(:translate_linter, result, locale) || result
  end

  class Error < RuntimeError; end
end
