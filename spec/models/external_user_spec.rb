# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExternalUser do
  let(:user) { described_class.create }

  it 'validates the presence of a consumer' do
    expect(user.errors[:consumer]).to be_present
  end

  it 'validates the presence of an external ID' do
    expect(user.errors[:external_id]).to be_present
  end

  describe '#admin?' do
    it 'is false' do
      expect(build(:external_user).admin?).to be false
    end
  end

  describe '#external_user?' do
    it 'is true' do
      expect(user.external_user?).to be true
    end
  end

  describe '#internal_user?' do
    it 'is false' do
      expect(user.internal_user?).to be false
    end
  end

  describe '#teacher?' do
    it 'is false' do
      expect(build(:external_user).teacher?).to be false
    end
  end

  describe 'external_user has no current_study_group_id' do
    it 'defaults to being a learner' do
      expect(build(:external_user).learner?).to be true
    end
  end

  describe '#soft_delete' do
    let(:user) { create(:external_user, name: 'Test User', email: 'testmail@gmail.com') }

    it 'sets the name to "Deleted User" and email to nil' do
      user.soft_delete
      expect(user.name).to eq('Deleted User')
      expect(user.email).to be_nil
    end

    it 'raises an error if the update fails' do
      allow(user).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(user))
      expect { user.soft_delete }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
