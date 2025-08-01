# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserContentReportMailer do
  describe '#report_content' do
    subject(:mail) { described_class.with(reported_content:).report_content }

    let(:reported_content) { instance_double(Comment) }
    let(:reported_message) { 'Repoted message' }
    let(:human_model_name) { 'ReportedModle' }
    let(:course_url) { 'https://example.com/course/1' }

    before do
      user_content_report = instance_double(UserContentReport,
        human_model_name:,
        reported_message:,
        related_request_for_comment: instance_double(RequestForComment),
        course_url:)
      allow(UserContentReport).to receive(:new).with(reported_content:).and_return(user_content_report)
    end

    it 'sets the correct sender' do
      expect(mail.from).to include('codeocean@openhpi.de')
    end

    it 'includes the reported content' do
      expect(mail.text_part.body).to include(reported_message)
      expect(mail.html_part.body).to include(reported_message)
    end

    it 'sets the correct subject' do
      expect(mail.subject).to eq(I18n.t('user_content_report_mailer.report_content.subject', human_model_name:))
    end

    it 'includes the LTI retrun URL for course authentication' do
      expect(mail.text_part.body).to include(course_url)
      expect(mail.html_part.body).to include(course_url)
    end
  end
end
