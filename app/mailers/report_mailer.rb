# frozen_string_literal: true

class ReportMailer < ApplicationMailer
  default to: CodeOcean::Config.new(:code_ocean).read.dig(:content_moderation, :report_emails)

  def report_content
    @reported_content = params.fetch(:reported_content)

    mail(subject: "Spam Report: A #{@reported_content.class.name} on CodeOcean has been marked as inappropriate.")
  end
end
