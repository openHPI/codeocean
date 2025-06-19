# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Exercise', :js do
  let(:study_group) do
    create(:study_group, external_id: nil)
  rescue StandardError
    StudyGroup.find_by(external_id: nil)
  end

  let(:teacher) { create(:teacher, study_groups: [study_group]) }

  before do
    create(:ruby)
    visit(sign_in_path)
    fill_in('email', with: teacher.email)
    fill_in('password', with: attributes_for(:teacher)[:password])
    click_button(I18n.t('sessions.new.link'))
  end

  it 'creates an exercise' do
    visit new_exercise_path

    fill_in :exercise_title, with: 'Ruby challenge'
    fill_in :exercise_internal_title, with: 'Project Ruby first challenge'

    within('.markdown-editor__wrapper') do
      find('.ProseMirror').set(<<~TEXT)
        # Ruby challenge

        Do something with Ruby.
      TEXT
    end

    binding.irb
    # fill_in :exercise_description, with: <<~TEXT
    #   # Ruby challenge

    #   Do something with Ruby.
    # TEXT

    # TODO: - set execution enviorment
    #       - add errors to exercises form
  end
end
