# frozen_string_literal: true

class UserContentReport
  def initialize(reported_content:)
    unless [Comment, RequestForComment].include?(reported_content.class)
      raise("#{reported_content.model_name} is not configured for content reports.")
    end

    @reported_content = reported_content
  end

  # NOTE: This implementation assumes the course URL is static and does not vary per user.
  # This is currently valid for a majority of use cases. However, in dynamic scenarios (such as
  # content trees in openHPI used in conjunction with A/B/n testing) this assumption may no
  # longer hold true.
  def course_url = lti_parameters['launch_presentation_return_url']

  def human_model_name = @reported_content.model_name.human

  def reported_message
    case @reported_content
      when RequestForComment
        @reported_content.question
      when Comment
        @reported_content.text
    end
  end

  def related_request_for_comment
    case @reported_content
      when RequestForComment
        @reported_content
      when Comment
        @reported_content.request_for_comment
    end
  end

  private

  def lti_parameters
    LtiParameter.find_by(study_group:, exercise:)&.lti_parameters || {}
  end

  def study_group
    @reported_content.submission.study_group
  end

  def exercise
    related_request_for_comment.exercise
  end
end
