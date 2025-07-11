# frozen_string_literal: true

class ReportMailer < ApplicationMailer
  default to: CodeOcean::Config.new(:code_ocean).read.dig(:content_moderation, :report_emails)

  def report_content
    @spam_report = SpamReport.new(reported_content: params.fetch(:reported_content))

    mail(subject: I18n.t('report_mailer.report_content.subject', human_model_name: @spam_report.human_model_name))
  end
end
