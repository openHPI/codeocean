# frozen_string_literal: true

module ExerciseHelper
  include LtiHelper

  CODEPILOT_CONFIG = CodeOcean::Config.new(:code_ocean).read[:code_pilot]

  def embedding_parameters(exercise)
    "locale=#{I18n.locale}&token=#{exercise.token}"
  end

  def qa_js_tag
    javascript_include_tag "#{qa_url}/assets/qa_api.js", integrity: true, crossorigin: 'anonymous'
  end

  def qa_url
    CODEPILOT_CONFIG[:url] if CODEPILOT_CONFIG[:enabled]
  end
end
