# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ExternalUserStatistics', :js do
  let(:learner) { create(:external_user) }
  let(:exercise) { create(:fibonacci, user:) }
  let(:study_group) { create(:study_group) }
  let(:password) { 'password123456' }

  before do
    2.times { create(:submission, cause: 'autosave', contributor: learner, exercise:, study_group:) }
    2.times { create(:submission, cause: 'run', contributor: learner, exercise:, study_group:) }
    create(:submission, cause: 'assess', contributor: learner, exercise:, study_group:)
    create(:submission, cause: 'submit', contributor: learner, exercise:, study_group:)

    study_group.external_users << learner
    study_group.internal_users << user
    study_group.save

    visit(sign_in_path)
    fill_in('email', with: user.email)
    fill_in('password', with: password)
    click_button(I18n.t('sessions.new.link')) # rubocop:disable Capybara/ClickLinkOrButtonStyle
    allow_any_instance_of(LtiHelper).to receive(:lti_outcome_service?).and_return(true)
    visit(statistics_external_user_exercise_path(id: exercise.id, external_user_id: learner.id))
  end

  context 'when a admin accesses the page' do
    let(:user) { create(:admin, password:) }

    it 'does display the option to enable autosaves' do
      expect(page).to have_content(I18n.t('exercises.external_users.statistics.toggle_status_on')).or have_content(I18n.t('exercises.external_users.statistics.toggle_status_off'))
    end
  end

  context 'when a teacher accesses the page' do
    let(:user) { create(:teacher, password:) }

    it 'does not display the option to enable autosaves' do
      expect(page).to have_no_content(I18n.t('exercises.external_users.statistics.toggle_status_on'))
      expect(page).to have_no_content(I18n.t('exercises.external_users.statistics.toggle_status_off'))
    end
  end
end
