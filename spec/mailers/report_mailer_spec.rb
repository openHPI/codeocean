# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportMailer do
  describe '#report_content' do
    subject(:mail) { described_class.with(reported_content:).report_content }

    let(:reported_content) { create(:rfc, question: 'Inappropriate content for RfC.') }

    it 'sets the correct sender' do
      expect(mail.from).to include('codeocean@openhpi.de')
    end

    context 'when an RfC is reported' do
      it 'sets the correct subject' do
        expect(mail.subject).to eq(I18n.t('report_mailer.report_content.subject', content_name: RequestForComment.model_name.human))
      end

      it 'includes the reported content' do
        expect(mail.text_part.body).to include('Inappropriate content for RfC.')
        expect(mail.html_part.body).to include('Inappropriate content for RfC.')
      end
    end
  end
end
