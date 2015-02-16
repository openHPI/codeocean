require 'rails_helper'

describe ExternalUser do
  let(:user) { described_class.create }

  it 'validates the presence of a consumer' do
    expect(user.errors[:consumer_id]).to be_present
  end

  it 'validates the presence of an external ID' do
    expect(user.errors[:external_id]).to be_present
  end

  describe '#admin?' do
    it 'is false' do
      expect(FactoryGirl.build(:external_user).admin?).to be false
    end
  end

  describe '#teacher?' do
    it 'is false' do
      expect(FactoryGirl.build(:external_user).teacher?).to be false
    end
  end
end
