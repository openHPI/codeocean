# frozen_string_literal: true

class UserContentReportMailerPreview < ActionMailer::Preview
  def report
    rfc = FactoryBot.build_stubbed(:rfc)

    UserContentReportMailer.with(reported_content: rfc).report_content
  end
end
