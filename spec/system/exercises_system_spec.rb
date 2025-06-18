# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Exercise', :js do
  let(:teacher) { create(:teacher) }

  before do
    visit(sign_in_path)
    fill_in('email', with: teacher.email)
    fill_in('password', with: attributes_for(:teacher)[:password])
    click_button(I18n.t('sessions.new.link'))
  end

  it 'creates an exercise' do
    visit new_exercise_path

    fill_in :exercise_title, with: 'xxx'

    # TODO: - set execution enviorment
    #       - add errors to exercises form
  end
end
