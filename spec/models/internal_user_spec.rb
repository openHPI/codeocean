# frozen_string_literal: true

require 'rails_helper'

describe InternalUser do
  let(:password) { SecureRandom.hex }
  let(:user) { described_class.create }

  it 'validates the presence of an email address' do
    expect(user.errors[:email]).to be_present
  end

  it 'validates the uniqueness of the email address' do
    user.update(email: create(:admin).email)
    expect(user.errors[:email]).to be_present
  end

  context 'when not activated' do
    let(:user) { create(:teacher) }

    before do
      user.send(:setup_activation)
      user.send(:send_activation_needed_email!)
    end

    it 'validates the confirmation of the password' do
      user.update(password:, password_confirmation: '')
      expect(user.errors[:password_confirmation]).to be_present
    end

    it 'validates the presence of a password' do
      user.update(name: Forgery(:name).full_name)
      expect(user.errors[:password]).to be_present
    end
  end

  context 'with a pending password reset' do
    let(:user) { create(:teacher) }

    before { user.deliver_reset_password_instructions! }

    it 'validates the confirmation of the password' do
      user.update(password:, password_confirmation: '')
      expect(user.errors[:password_confirmation]).to be_present
    end

    it 'validates the presence of a password' do
      user.update(name: Forgery(:name).full_name)
      expect(user.errors[:password]).to be_present
    end
  end

  context 'when complete' do
    let(:user) { create(:teacher, activation_state: 'active') }

    it 'does not validate the confirmation of the password' do
      user.update(password:, password_confirmation: '')
      expect(user.errors[:password_confirmation]).not_to be_present
    end

    it 'does not validate the presence of a password' do
      expect(user.errors[:password]).not_to be_present
    end
  end

  it 'validates the presence of the platform_admin flag' do
    user.update(platform_admin: nil)
    expect(user.errors[:platform_admin]).to be_present
  end

  describe '#admin?' do
    it 'is only true for admins' do
      expect(build(:admin).admin?).to be true
      expect(build(:teacher).admin?).to be false
    end
  end

  describe '#external_user?' do
    it 'is false' do
      expect(user.external_user?).to be false
    end
  end

  describe '#internal_user?' do
    it 'is true' do
      expect(user.internal_user?).to be true
    end
  end

  describe '#teacher?' do
    it 'is only true for teachers' do
      expect(create(:admin).teacher?).to be false
      expect(create(:teacher).teacher?).to be true
    end
  end
end
