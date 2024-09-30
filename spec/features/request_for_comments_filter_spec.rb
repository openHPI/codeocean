# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Request_for_Comments' do
  let(:user) { create(:teacher) }

  before do
    visit(sign_in_path)
    fill_in('email', with: user.email)
    fill_in('password', with: attributes_for(:teacher)[:password])
    click_button(I18n.t('sessions.new.link')) # rubocop:disable Capybara/ClickLinkOrButtonStyle
  end

  it 'does not contain rfcs for unpublished exercises' do
    unpublished_rfc = create(:rfc)
    unpublished_rfc.exercise.update(title: 'Unpublished Exercise')
    unpublished_rfc.exercise.update(unpublished: true)
    rfc = create(:rfc)
    rfc.exercise.update(title: 'Normal Exercise')
    rfc.exercise.update(unpublished: false)

    visit(request_for_comments_path)

    expect(page).to have_content(rfc.exercise.title)
    expect(page).to have_no_content(unpublished_rfc.exercise.title)
  end

  it 'contains a filter for study group in the view' do
    visit(request_for_comments_path)
    expect(page.find_by_id('q_submission_study_group_id_in')).not_to be_nil
  end

  it 'works with the pagination' do
    submission = create(:submission)
    create_list(:rfc, 25, submission:, exercise: submission.exercise) # rubocop:disable FactoryBot/ExcessiveCreateList
    visit(request_for_comments_path)
    expect(page).to have_css('ul.pagination')
  end
end
