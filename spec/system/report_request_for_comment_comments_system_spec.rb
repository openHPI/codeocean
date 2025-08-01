# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Report RfC comments for inappropriate content', :js do
  let(:user) { create(:learner) }

  before do
    stub_const('CommentPolicy::REPORT_RECEIVER_CONFIGURED', reports_enabled)
    visit(sign_in_path)
    fill_in('email', with: user.email)
    fill_in('password', with: attributes_for(:learner)[:password])
    click_button(I18n.t('sessions.new.link'))
    visit(request_for_comment_path(create(:rfc_with_comment)))
    find('span.ace_icon').click
  end

  context 'when reporting is enabled' do
    let(:reports_enabled) { true }

    it 'allows reporting of RfCs' do
      within('.modal-content') do
        click_on I18n.t('shared.report')
      end

      expect(page).to have_text(I18n.t('comments.reported'))
    end
  end

  context 'when reporting is disabled' do
    let(:reports_enabled) { false }

    it 'does not display the report button' do
      within('.modal-content') do
        expect(page).to have_no_button(I18n.t('shared.report'))
      end
    end
  end
end
