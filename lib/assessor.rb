class Assessor
  MAXIMUM_SCORE = 1

  def assess(output)
    test_outcome = @testing_framework_adapter.test_outcome(output)
    test_outcome.merge(score: calculate_score(test_outcome))
  rescue Exception
    {score: 0}
  end

  def calculate_score(test_outcome)
    (test_outcome[:passed].to_f / test_outcome[:count].to_f)
  end
  private :calculate_score

  def initialize(options = {})
    if options[:execution_environment].testing_framework?
      @testing_framework_adapter = Kernel.const_get(options[:execution_environment].testing_framework).new
    else
      raise Error.new('No testing framework adapter set!')
    end
  end
end

class Assessor::Error < RuntimeError
end
