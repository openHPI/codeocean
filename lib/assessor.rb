class Assessor
  MAXIMUM_SCORE = 1

  def assess(output)
    test_outcome = @testing_framework_adapter.test_outcome(output)
    test_outcome.merge(score: calculate_score(test_outcome))
  rescue
    {score: 0}
  end

  def calculate_score(test_outcome)
    score = 0.0;
    if(test_outcome[:passed].to_f != 0.0 && test_outcome[:count].to_f != 0.0)
      score = (test_outcome[:passed].to_f / test_outcome[:count].to_f)
      # prevent negative scores
      score = [0.0, score].max
    end
    score
  end
  private :calculate_score

  def initialize(options = {})
    if options[:execution_environment].testing_framework?
      @testing_framework_adapter = Kernel.const_get(options[:execution_environment].testing_framework).new
    else
      fail(Error, 'No testing framework adapter set!')
    end
  end

  class Error < RuntimeError; end
end
