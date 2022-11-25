# frozen_string_literal: true

require 'rails_helper'

describe 'Authentication' do
  let(:user) { create(:admin) }
  let(:password) { attributes_for(:admin)[:password] }

  context 'when signed out' do
    before { visit(root_path) }

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

    context 'with no authentication token' do
      let(:request_for_comment) { create(:rfc_with_comment, user:) }
      let(:rfc_path) { request_for_comment_url(request_for_comment) }

      it 'denies access to the request for comment' do
        visit(rfc_path)
        expect(page).not_to have_current_path(rfc_path)
        expect(page).not_to have_content(request_for_comment.exercise.title)
        expect(page).to have_current_path(root_path)
        expect(page).to have_content(I18n.t('application.not_authorized'))
      end
    end

    context 'with an authentication token' do
      let(:user) { create(:learner) }
      let(:study_group) { request_for_comment.submission.study_group }
      let(:request_for_comment) { create(:rfc_with_comment, user:) }
      let(:commenting_user) { InternalUser.create(attributes_for(:teacher)) }
      let(:mail) { UserMailer.got_new_comment(request_for_comment.comments.first, request_for_comment, commenting_user) }
      let(:rfc_link) { request_for_comment_url(request_for_comment, token: token.shared_secret) }

      before { allow(AuthenticationToken).to receive(:generate!).with(user, study_group).and_return(token).once }

      context 'when the token is valid' do
        let(:token) { create(:authentication_token, user:, study_group:) }

        it 'allows access to the request for comment' do
          mail.deliver_now
          visit(rfc_link)
          expect(page).to have_current_path(rfc_link)
          expect(page).to have_content(request_for_comment.exercise.title)
        end
      end

      context 'with an expired authentication token' do
        let(:token) { create(:authentication_token, :invalid, user:, study_group:) }

        it 'denies access to the request for comment' do
          mail.deliver_now
          visit(rfc_link)
          expect(page).not_to have_current_path(rfc_link)
          expect(page).not_to have_content(request_for_comment.exercise.title)
          expect(page).to have_current_path(root_path)
          expect(page).to have_content(I18n.t('application.not_authorized'))
        end
      end

      context 'when the authentication token is used to login' do
        let(:token) { create(:authentication_token, user:, study_group:) }

        it 'invalidates the token on login' do
          mail.deliver_now
          visit(rfc_link)
          expect(token.reload.expire_at).to be_within(10.seconds).of(Time.zone.now)
        end

        it 'does not allow a second login' do
          mail.deliver_now
          visit(rfc_link)
          expect(page).to have_current_path(rfc_link)
          visit(sign_out_path)
          visit(rfc_link)
          expect(page).to have_current_path(root_path)
        end
      end
    end
  end

  context 'when signed in' do
    before do
      sign_in(user, password)
      visit(root_path)
    end

    context 'with an authentication token' do
      let(:request_for_comment) { create(:rfc_with_comment, user:) }
      let(:study_group) { request_for_comment.submission.study_group }
      let(:commenting_user) { InternalUser.create(attributes_for(:teacher)) }
      let(:mail) { UserMailer.got_new_comment(request_for_comment.comments.first, request_for_comment, commenting_user) }
      let(:rfc_link) { request_for_comment_url(request_for_comment, token: token.shared_secret) }

      it 'still invalidates the token on login' do
        token = create(:authentication_token, user:, study_group:)
        mail = UserMailer.got_new_comment(request_for_comment.comments.first, request_for_comment, commenting_user)
        mail.deliver_now
        visit(request_for_comment_url(request_for_comment, token: token.shared_secret))
        expect(token.reload.expire_at).to be_within(10.seconds).of(Time.zone.now)
      end
    end

    it "displays the user's displayname" do
      expect(page).to have_content(user.displayname)
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
