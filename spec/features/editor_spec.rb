require 'rails_helper'

describe 'Editor', js: true do
  let(:exercise) { FactoryBot.create(:audio_video, instructions: Forgery(:lorem_ipsum).sentence) }
  let(:user) { FactoryBot.create(:teacher) }

  before(:each) do
    visit(sign_in_path)
    fill_in('email', with: user.email)
    fill_in('password', with: FactoryBot.attributes_for(:teacher)[:password])
    click_button(I18n.t('sessions.new.link'))
    visit(implement_exercise_path(exercise))
  end

  skip "is skipped" do
    # selenium tests are currently not working locally.
    it 'displays the exercise title' do
      expect(page).to have_content(exercise.title)
    end
  end

  describe 'Instructions Tab' do
    skip "is skipped" do

    before(:each) { click_link(I18n.t('activerecord.attributes.exercise.instructions')) }

    it 'displays the exercise instructions' do
      expect(page).to have_content(exercise.instructions)
    end
    end
  end

  describe 'Workspace Tab' do
    skip "is skipped" do

    before(:each) { click_link(I18n.t('exercises.implement.workspace')) }

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
        let(:file) { exercise.files.detect { |file| !file.file_type.binary? } }

        it "displays the file's code" do
          expect(page).to have_css(".frame[data-filename='#{file.name_with_extension}']")
        end
      end
    end
    end
  end

  describe 'Progress Tab' do
    skip "is skipped" do
      before(:each) { click_link(I18n.t('exercises.implement.progress')) }

      it 'does not contains a button for submitting the exercise' do
        # pending("the button is only displayed when an correct LTI handshake to a running course happened. This is not the case in the test")
        expect(page).not_to have_css('#submit')
      end
    end
  end
end
