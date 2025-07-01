# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Report RfCs for inappropriate content' do
  let(:user) { create(:learner) }

  before do
    stub_const('RequestForCommentPolicy::REPORT_RECEIVER_CONFIGURED', reports_enabled)
    visit(sign_in_path)
    fill_in('email', with: user.email)
    fill_in('password', with: attributes_for(:learner)[:password])
    click_button(I18n.t('sessions.new.link'))
    visit(request_for_comment_path(create(:rfc)))
  end

  context 'when reporting is enabled' do
    let(:reports_enabled) { true }

    it 'allows reporting of RfCs', :js do
      accept_confirm do
        click_on I18n.t('request_for_comments.report.report')
      end

      expect(page).to have_text(I18n.t('request_for_comments.report.reported'))
    end
  end

  context 'when reporting is disabled' do
    let(:reports_enabled) { false }

    it 'does not display the report button' do
      expect(page).to have_no_button(I18n.t('request_for_comments.report.report'))
    end
  end
end
