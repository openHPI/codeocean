require 'rails_helper'

describe UserMailer do
  let(:user) { InternalUser.create(FactoryBot.attributes_for(:teacher)) }

  describe '#activation_needed_email' do
    let(:mail) { described_class.activation_needed_email(user) }

    before(:each) do
      user.send(:setup_activation)
      user.save(validate: false)
    end

    it 'sets the correct sender' do
      expect(mail.from).to include(CodeOcean::Application.config.action_mailer[:default_options][:from])
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

    it 'sets the correct sender' do
      expect(mail.from).to include(CodeOcean::Application.config.action_mailer[:default_options][:from])
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
end
