# frozen_string_literal: true

require 'rails_helper'

describe Admin::DashboardPolicy do
  subject(:policy) { described_class }

  permissions :show? do
    it 'grants access to admins' do
      expect(policy).to permit(FactoryBot.build(:admin), :dashboard)
    end

    it 'does not grant access to teachers' do
      expect(policy).not_to permit(FactoryBot.build(:teacher), :dashboard)
    end

    it 'does not grant access to external users' do
      expect(policy).not_to permit(FactoryBot.build(:external_user), :dashboard)
    end
  end
end
