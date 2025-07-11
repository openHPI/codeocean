# frozen_string_literal: true

class UserContentReportMailer < ApplicationMailer
  default to: CodeOcean::Config.new(:code_ocean).read.dig(:content_moderation, :report_emails)

  def report_content
    @user_content_report = UserContentReport.new(reported_content: params.fetch(:reported_content))

    mail(subject: I18n.t('user_content_report_mailer.report_content.subject', human_model_name: @user_content_report.human_model_name))
  end
end
