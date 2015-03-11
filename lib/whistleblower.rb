class Whistleblower
  PLACEHOLDER_REGEXP = /\$(\d)/

  def find_hint(stderr)
    @execution_environment.hints.detect do |hint|
      @matches = Regexp.new(hint.regular_expression).match(stderr)
    end
  end
  private :find_hint

  def generate_hint(stderr)
    if hint = find_hint(stderr)
      hint.message.gsub(PLACEHOLDER_REGEXP) { @matches[Regexp.last_match(1).to_i] }
    end
  end

  def initialize(options = {})
    @execution_environment = options[:execution_environment]
  end
end
