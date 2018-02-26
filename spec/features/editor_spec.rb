require 'rails_helper'

describe 'Editor', js: true do
  let(:exercise) { FactoryBot.create(:audio_video, description: Forgery(:lorem_ipsum).sentence) }
  let(:user) { FactoryBot.create(:teacher) }

  before(:each) do
    visit(sign_in_path)
    fill_in('email', with: user.email)
    fill_in('password', with: FactoryBot.attributes_for(:teacher)[:password])
    click_button(I18n.t('sessions.new.link'))
    expect_any_instance_of(LtiHelper).to receive(:lti_outcome_service?).and_return(true)
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
    before(:each) do
      within('#files') { click_link(file.name_with_extension) }
    end

    context 'when selecting a binary file' do
      context 'when selecting an audio file' do
        let(:file) { exercise.files.detect { |file| file.file_type.audio? } }

        it 'contains an <audio> tag' do
          expect(page).to have_css("audio[src='#{file.native_file.url}']")
        end
      end

      context 'when selecting an image file' do
        let(:file) { exercise.files.detect { |file| file.file_type.image? } }

        it 'contains an <img> tag' do
          expect(page).to have_css("img[src='#{file.native_file.url}']")
        end
      end

      context 'when selecting a video file' do
        let(:file) { exercise.files.detect { |file| file.file_type.video? } }

        it 'contains a <video> tag' do
          expect(page).to have_css("video[src='#{file.native_file.url}']")
        end
      end
    end

    context 'when selecting a non-binary file' do
      let(:file) { exercise.files.detect { |file| !file.file_type.binary? && !file.hidden? } }

      it "displays the file's code" do
        expect(page).to have_css(".frame[data-filename='#{file.name_with_extension}']")
      end
    end
  end

  it 'does not contains a button for submitting the exercise' do
    click_button(I18n.t('exercises.editor.score'))
    click_button('toggle-sidebar-output-collapsed')
    expect(page).not_to have_css('#submit_outdated')
    expect(page).to have_css('#submit')
  end
end
