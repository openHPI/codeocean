require 'rails_helper'

describe Admin::DashboardPolicy do
  subject { described_class }

  permissions :show? do
    it 'grants access to admins' do
      expect(subject).to permit(FactoryBot.build(:admin), :dashboard)
    end

    it 'does not grant access to teachers' do
      expect(subject).not_to permit(FactoryBot.build(:teacher), :dashboard)
    end

    it 'does not grant access to external users' do
      expect(subject).not_to permit(FactoryBot.build(:external_user), :dashboard)
    end
  end
end
