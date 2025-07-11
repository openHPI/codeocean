# frozen_string_literal: true

class ReportMailer < ApplicationMailer
  default to: CodeOcean::Config.new(:code_ocean).read.dig(:content_moderation, :report_emails)

  def report_content
    @reported_content = params.fetch(:reported_content)
    study_group = @reported_content.submission.study_group
    exercise = @reported_content.exercise

    # NOTE: This implementation assumes the curse URL is static and does not vary per user.
    # This is currently valid for all known use cases. However, in dynamic environments—such as
    # advanced content trees in openHPI or A/B/n testing—this assumption may break.
    @course_url = LtiParameter.find_by(study_group:, exercise:)&.lti_parameters&.[]('launch_presentation_return_url')

    mail(subject: I18n.t('report_mailer.report_content.subject', content_name: @reported_content.model_name.human))
  end
end
