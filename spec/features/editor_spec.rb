# frozen_string_literal: true

require 'rails_helper'

describe 'Editor', js: true do
  let(:exercise) { create(:audio_video, description: Forgery(:lorem_ipsum).sentence) }
  let(:scoring_response) do
    [{
      status: :ok,
      stdout: '',
      stderr: '',
      waiting_for_container_time: 0,
      container_execution_time: 0,
      file_role: 'teacher_defined_test',
      count: 1,
      failed: 0,
      error_messages: [],
      passed: 1,
      score: 1.0,
      filename: 'index.html_spec.rb',
      message: 'Well done.',
      weight: 2.0,
    }]
  end
  let(:user) { create(:teacher) }
  let(:exercise_without_test) { create(:tdd) }

  before do
    visit(sign_in_path)
    fill_in('email', with: user.email)
    fill_in('password', with: attributes_for(:teacher)[:password])
    click_button(I18n.t('sessions.new.link'))
    allow_any_instance_of(LtiHelper).to receive(:lti_outcome_service?).and_return(true)
    visit(implement_exercise_path(exercise))
  end

  it 'displays the exercise title' do
    expect(page).to have_content(exercise.title)
  end

  it 'displays the exercise description' do
    expect(page).to have_content(exercise.description)
  end

  it 'displays all visible files in a file tree' do
    within('#files') do
      exercise.files.select(&:visible).each do |file|
        expect(page).to have_content(file.name_with_extension)
      end
    end
  end

  it "displays the main file's code" do
    expect(page).to have_css(".frame[data-filename='#{exercise.files.detect(&:main_file?).name_with_extension}']")
  end

  context 'when selecting a file' do
    before do
      within('#files') { click_link(file.name_with_extension) }
    end

    context 'when selecting a binary file' do
      context 'when selecting an audio file' do
        let(:file) { exercise.files.detect {|file| file.file_type.audio? } }

        it 'contains an <audio> tag' do
          expect(page).to have_css("audio[src='#{file.native_file.url}']")
        end
      end

      context 'when selecting an image file' do
        let(:file) { exercise.files.detect {|file| file.file_type.image? } }

        it 'contains an <img> tag' do
          expect(page).to have_css("img[src='#{file.native_file.url}']")
        end
      end

      context 'when selecting a video file' do
        let(:file) { exercise.files.detect {|file| file.file_type.video? } }

        it 'contains a <video> tag' do
          expect(page).to have_css("video[src='#{file.native_file.url}']")
        end
      end
    end

    context 'when selecting a non-binary file' do
      let(:file) { exercise.files.detect {|file| !file.file_type.binary? && !file.hidden? } }

      it "displays the file's code" do
        expect(page).to have_css(".frame[data-filename='#{file.name_with_extension}']")
      end
    end
  end

  context 'when an exercise has one or more teacher-defined assessments' do
    it 'displays the score button' do
      visit(implement_exercise_path(exercise))
      expect(page).to have_content(exercise.title)
      expect(page).to have_content(I18n.t('exercises.editor.score'))
    end
  end

  context 'when an exercise has no teacher-defined assessment' do
    it 'disables the score button' do
      visit(implement_exercise_path(exercise_without_test))
      expect(page).to have_content(exercise_without_test.title)
      expect(page).not_to have_content(I18n.t('exercises.editor.score'))
    end
  end

  it 'contains a button for submitting the exercise' do
    submission = build(:submission, user:, exercise:)
    allow(submission).to receive(:calculate_score).and_return(scoring_response)
    allow(Submission).to receive(:find).and_return(submission)
    click_button(I18n.t('exercises.editor.score'))
    expect(page).not_to have_content(I18n.t('exercises.editor.tooltips.exercise_deadline_passed'))
    expect(page).to have_content(I18n.t('exercises.editor.submit'))
  end
end
