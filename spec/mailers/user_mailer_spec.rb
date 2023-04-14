# frozen_string_literal: true

require 'rails_helper'

describe UserMailer do
  let(:user) { InternalUser.create(attributes_for(:teacher)) }

  describe '#activation_needed_email' do
    let(:mail) { described_class.activation_needed_email(user) }

    before do
      user.send(:setup_activation)
      user.save(validate: false)
    end

    it 'sets the correct sender' do
      expect(mail.from).to include('codeocean@openhpi.de')
    end

    it 'sets the correct subject' do
      expect(mail.subject).to eq(I18n.t('mailers.user_mailer.activation_needed.subject'))
    end

    it 'sets the correct receiver' do
      expect(mail.to).to include(user.email)
    end

    it 'includes the correct URL' do
      expect(mail.body).to include(activate_internal_user_url(user, token: user.activation_token))
    end
  end

  describe '#activation_success_email' do
    it 'does not raise an error' do
      expect { described_class.activation_success_email(user) }.not_to raise_error
    end
  end

  describe '#reset_password_email' do
    let(:mail) { described_class.reset_password_email(user) }

    before do
      user.send(:setup_activation)
      user.save(validate: false)
    end

    it 'sets the correct sender' do
      expect(mail.from).to include('codeocean@openhpi.de')
    end

    it 'sets the correct subject' do
      expect(mail.subject).to eq(I18n.t('mailers.user_mailer.reset_password.subject'))
    end

    it 'sets the correct receiver' do
      expect(mail.to).to include(user.email)
    end

    it 'includes the correct URL' do
      expect(mail.body).to include(reset_password_internal_user_url(user, token: user.reset_password_token))
    end
  end

  describe '#got_new_comment' do
    let(:user) { create(:learner) }
    let(:token) { AuthenticationToken.find_by(user:) }
    let(:request_for_comment) { create(:rfc_with_comment, user:) }
    let(:commenting_user) { InternalUser.create(attributes_for(:teacher)) }
    let(:mail) { described_class.got_new_comment(request_for_comment.comments.first, request_for_comment, commenting_user).deliver_now }

    it 'sets the correct sender' do
      expect(mail.from).to include('codeocean@openhpi.de')
    end

    it 'sets the correct subject' do
      expect(mail.subject).to eq(I18n.t('mailers.user_mailer.got_new_comment.subject', commenting_user_displayname: commenting_user.displayname))
    end

    it 'sets the correct receiver' do
      expect(mail.to).to include(request_for_comment.user.email)
    end

    it 'includes the correct URL' do
      expect(mail.body).to include(request_for_comment_url(request_for_comment, token: token.shared_secret))
    end

    it 'creates a new authentication token' do
      expect { mail }.to change(AuthenticationToken, :count).by(1)
    end

    it 'sets a non-expired authentication token' do
      mail
      # A five minute tolerance is allowed to account for the time difference between `now` and the creation timestamp of the token.
      expect(token.expire_at - Time.zone.now).to be_within(5.minutes).of(7.days)
    end

    it 'sets the correct comment' do
      expect(mail.body).to include(request_for_comment.comments.first.text)
    end

    context 'with an HTML comment' do
      let(:html_comment) { '<b>test</b>' }
      let(:escaped_comment) { '&lt;b&gt;test&lt;/b&gt;' }

      before { request_for_comment.comments.first.update(text: html_comment) }

      it 'does not include the HTML tags' do
        expect(mail.body).not_to include(html_comment)
      end

      it 'includes escaped HTML tags' do
        expect(mail.body).to include(escaped_comment)
      end
    end
  end

  describe '#got_new_comment_for_subscription' do
    let(:user) { create(:learner) }
    let(:token) { AuthenticationToken.find_by(user:) }
    let(:request_for_comment) { create(:rfc_with_comment, user:) }
    let(:subscription) { Subscription.create(request_for_comment:, user:, study_group_id: user.current_study_group_id) }
    let(:from_user) { InternalUser.create(attributes_for(:teacher)) }
    let(:mail) { described_class.got_new_comment_for_subscription(request_for_comment.comments.first, subscription, from_user).deliver_now }

    it 'sets the correct sender' do
      expect(mail.from).to include('codeocean@openhpi.de')
    end

    it 'sets the correct subject' do
      expect(mail.subject).to eq(I18n.t('mailers.user_mailer.got_new_comment_for_subscription.subject', author_displayname: from_user.displayname))
    end

    it 'sets the correct receiver' do
      expect(mail.to).to include(subscription.user.email)
    end

    it 'includes the correct URL' do
      expect(mail.body).to include(request_for_comment_url(subscription.request_for_comment, token: token.shared_secret))
    end

    it 'creates a new authentication token' do
      expect { mail }.to change(AuthenticationToken, :count).by(1)
    end

    it 'sets a non-expired authentication token' do
      mail
      # A five minute tolerance is allowed to account for the time difference between `now` and the creation timestamp of the token.
      expect(token.expire_at - Time.zone.now).to be_within(5.minutes).of(7.days)
    end

    it 'sets the correct comment' do
      expect(mail.body).to include(request_for_comment.comments.first.text)
    end

    context 'with an HTML comment' do
      let(:html_comment) { '<b>test</b>' }
      let(:escaped_comment) { '&lt;b&gt;test&lt;/b&gt;' }

      before { request_for_comment.comments.first.update(text: html_comment) }

      it 'does not include the HTML tags' do
        expect(mail.body).not_to include(html_comment)
      end

      it 'includes escaped HTML tags' do
        expect(mail.body).to include(escaped_comment)
      end
    end
  end

  describe '#send_thank_you_note' do
    let(:user) { create(:learner) }
    let(:receiver) { create(:teacher) }
    let(:token) { AuthenticationToken.find_by(user: receiver) }
    let(:request_for_comment) { create(:rfc_with_comment, user:) }
    let(:mail) { described_class.send_thank_you_note(request_for_comment, receiver).deliver_now }

    it 'sets the correct sender' do
      expect(mail.from).to include('codeocean@openhpi.de')
    end

    it 'sets the correct subject' do
      expect(mail.subject).to eq(I18n.t('mailers.user_mailer.send_thank_you_note.subject', author: request_for_comment.user.displayname))
    end

    it 'sets the correct receiver' do
      expect(mail.to).to include(receiver.email)
    end

    it 'includes the correct URL' do
      expect(mail.body).to include(request_for_comment_url(request_for_comment, token: token.shared_secret))
    end

    it 'creates a new authentication token' do
      expect { mail }.to change(AuthenticationToken, :count).by(1)
    end

    it 'sets a non-expired authentication token' do
      mail
      # A five minute tolerance is allowed to account for the time difference between `now` and the creation timestamp of the token.
      expect(token.expire_at - Time.zone.now).to be_within(5.minutes).of(7.days)
    end

    it 'sets the correct thank_you_note' do
      expect(mail.body).to include(request_for_comment.thank_you_note)
    end

    context 'with an HTML comment' do
      let(:html_comment) { '<b>test</b>' }
      let(:escaped_comment) { '&lt;b&gt;test&lt;/b&gt;' }

      before { request_for_comment.update(thank_you_note: html_comment) }

      it 'does not include the HTML tags' do
        expect(mail.body).not_to include(html_comment)
      end

      it 'includes escaped HTML tags' do
        expect(mail.body).to include(escaped_comment)
      end
    end
  end
end
