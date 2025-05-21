# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportMailer do
  describe '#report_content' do
    subject(:mail) { described_class.with(reported_content:).report_content }

    let(:reported_content) { create(:comment, text: 'Inappropriate content for Comment.') }

    context 'when e RfC is reported' do
      let(:reported_content) { create(:rfc, question: 'Inappropriate content for RfC.') }

      it 'sets the correct subject' do
        expect(mail.subject).to eq('Spam Report: A RequestForComment on CodeOcean has been marked as inappropriate.')
      end

      it 'includes the reported content' do
        expect(mail.body).to include('Inappropriate content for RfC.')
      end
    end

    it 'sets the correct sender' do
      expect(mail.from).to include('codeocean@openhpi.de')
    end

    it 'sets the correct subject' do
      expect(mail.subject).to eq('Spam Report: A Comment on CodeOcean has been marked as inappropriate.')
    end

    it 'sets the correct receiver' do
      expect(mail.to).to include('report@example.com')
    end

    it 'includes the reported content' do
      expect(mail.body).to include('Inappropriate content for Comment.')
    end
  end
end
