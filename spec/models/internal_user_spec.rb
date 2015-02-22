require 'rails_helper'

describe InternalUser do
  let(:password) { SecureRandom.hex }
  let(:user) { described_class.create }

  it 'validates the presence of an email address' do
    expect(user.errors[:email]).to be_present
  end

  it 'validates the uniqueness of the email address' do
    user.update(email: FactoryGirl.create(:admin).email)
    expect(user.errors[:email]).to be_present
  end

  context 'when activated' do
    let(:user) { FactoryGirl.create(:teacher, activation_state: 'active') }

    it 'does not validate the confirmation of the password' do
      user.update(password: password, password_confirmation: '')
      expect(user.errors[:password_confirmation]).not_to be_present
    end

    it 'does not validate the presence of a password' do
      expect(user.errors[:password]).not_to be_present
    end
  end

  context 'when not activated' do
    let(:user) { described_class.create(FactoryGirl.attributes_for(:teacher, activation_state: 'pending', password: nil)) }

    it 'validates the confirmation of the password' do
      user.update(password: password, password_confirmation: '')
      expect(user.errors[:password_confirmation]).to be_present
    end

    it 'validates the presence of a password' do
      user.update(name: Forgery(:name).full_name)
      expect(user.errors[:password]).to be_present
    end
  end

  it 'validates the domain of the role' do
    user.update(role: 'Foo')
    expect(user.errors[:role]).to be_present
  end

  it 'validates the presence of a role' do
    expect(user.errors[:role]).to be_present
  end

  describe '#admin?' do
    it 'is only true for admins' do
      expect(FactoryGirl.build(:admin).admin?).to be true
      expect(FactoryGirl.build(:teacher).admin?).to be false
    end
  end

  describe '#teacher?' do
    it 'is only true for teachers' do
      expect(FactoryGirl.build(:admin).teacher?).to be false
      expect(FactoryGirl.build(:teacher).teacher?).to be true
    end
  end
end
