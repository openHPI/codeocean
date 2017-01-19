module ExerciseHelper
  include LtiHelper

  def embedding_parameters(exercise)
    "locale=#{I18n.locale}&token=#{exercise.token}"
  end

  def qa_js_tag
    javascript_include_tag qa_url + "/assets/qa_api.js"
  end

  def qa_url
    config = CodeOcean::Config.new(:code_ocean)
    enabled = config.read[:code_pilot][:enabled]

    if enabled
      config.read[:code_pilot][:url]
    else
      return nil
    end
  end
end
