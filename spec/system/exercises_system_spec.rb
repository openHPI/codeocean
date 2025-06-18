# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Exercise', :js do
  before do
    teacher = create(:teacher)
    visit(sign_in_path)
    fill_in('email', with: teacher.email)
    fill_in('password', with: attributes_for(:teacher)[:password])
    binding.irb
    click_button(I18n.t('sessions.new.link'))
  end

  it 'foo' do
    visit new_exercise_path

    binding.irb
  end
end
