# frozen_string_literal: true

module ScoringResultFormatting
  def format_scoring_results(outputs)
    outputs.map do |output|
      output[:message] = t(output[:message], default: render_markdown(output[:message]))
      output[:filename] = t(output[:filename], default: output[:filename])
      output
    end
  end
end
