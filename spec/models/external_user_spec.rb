# frozen_string_literal: true

require 'rails_helper'

describe ExternalUser do
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
end
