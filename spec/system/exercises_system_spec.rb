# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Exercise', :js do
  # TODO: Research why the base study group is created more then once.
  let(:study_group) do
    create(:study_group, external_id: nil)
  rescue StandardError
    StudyGroup.find_by(external_id: nil)
  end

  # Only teachers in the base study group will be teachers after sign in.
  # Teachers from other sources need to session parameters.
  let(:teacher) { create(:teacher, study_groups: [study_group]) }

  before do
    create(:ruby)
    visit(sign_in_path)
    fill_in('email', with: teacher.email)
    fill_in('password', with: attributes_for(:teacher)[:password])
    click_button(I18n.t('sessions.new.link'))
    wait_for_ajax
  end

  it 'creates a minimal exercise' do
    visit new_exercise_path

    fill_in :exercise_title, with: 'Ruby challenge'
    fill_in :exercise_internal_title, with: 'Project Ruby first challenge'

    within('.markdown-editor__wrapper') do
      find('.ProseMirror').set(<<~TEXT)
        # Ruby challenge

        Do something with Ruby.
      TEXT
    end

    chosen_select('exercise_execution_environment_id_chosen', 'Ruby 2.2')

    submission_deadline = 3.months.from_now

    chosen_select('exercise_submission_deadline_1i_chosen', submission_deadline.year.to_s)
    chosen_select('exercise_submission_deadline_2i_chosen', submission_deadline.strftime('%B'))
    chosen_select('exercise_submission_deadline_3i_chosen', submission_deadline.day.to_s)
    chosen_select('exercise_submission_deadline_4i_chosen', submission_deadline.hour.to_s)
    chosen_select('exercise_submission_deadline_5i_chosen', submission_deadline.min.to_s)

    late_submission_deadline = submission_deadline + 1.week

    chosen_select('exercise_late_submission_deadline_1i_chosen', late_submission_deadline.year.to_s)
    chosen_select('exercise_late_submission_deadline_2i_chosen', late_submission_deadline.strftime('%B'))
    chosen_select('exercise_late_submission_deadline_3i_chosen', late_submission_deadline.day.to_s)
    chosen_select('exercise_late_submission_deadline_4i_chosen', late_submission_deadline.hour.to_s)
    chosen_select('exercise_late_submission_deadline_5i_chosen', late_submission_deadline.min.to_s)

    check 'Public'

    fill_in 'Difficulty', with: 5

    click_on 'Create Exercise'

    expect(page).to have_text 'Exercise has successfully been created.'
  end

  def chosen_select(id, value)
    element = find_by_id(id)
    element.click

    within(element) do
      first('.chosen-results li', text: value).click
    end
  end
end
