# frozen_string_literal: true

class ReportMailerPreview < ActionMailer::Preview
  def report
    rfc = FactoryBot.build_stubbed(:rfc)

    ReportMailer.with(reported_content: rfc).report_content
  end
end
