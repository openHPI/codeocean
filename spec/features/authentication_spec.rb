require 'rails_helper'

describe 'Authentication' do
  let(:user) { FactoryBot.create(:admin) }
  let(:password) { FactoryBot.attributes_for(:admin)[:password] }

  context 'when signed out' do
    before(:each) { visit(root_path) }

    it 'displays a sign in link' do
      expect(page).to have_content(I18n.t('sessions.new.link'))
    end

    context 'with valid credentials' do
      it 'allows to sign in' do
        click_link(I18n.t('sessions.new.link'))
        fill_in('Email', with: user.email)
        fill_in('Password', with: password)
        click_button(I18n.t('sessions.new.link'))
        expect(page).to have_content(I18n.t('sessions.create.success'))
      end
    end

    context 'with invalid credentials' do
      it 'does not allow to sign in' do
        click_link(I18n.t('sessions.new.link'))
        fill_in('Email', with: user.email)
        fill_in('Password', with: password.reverse)
        click_button(I18n.t('sessions.new.link'))
        expect(page).to have_content(I18n.t('sessions.create.failure'))
      end
    end
  end

  context 'when signed in' do
    before(:each) do
      sign_in(user, password)
      visit(root_path)
    end

    it "displays the user's name" do
      expect(page).to have_content(user.name)
    end

    it 'displays a sign out link' do
      expect(page).to have_content(I18n.t('sessions.destroy.link'))
    end

    it 'allows to sign out' do
      click_link(I18n.t('sessions.destroy.link'))
      expect(page).to have_content(I18n.t('sessions.destroy.success'))
    end
  end
end
