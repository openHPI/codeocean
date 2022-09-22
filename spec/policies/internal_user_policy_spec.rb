# frozen_string_literal: true

require 'rails_helper'

describe InternalUserPolicy do
  subject(:policy) { described_class }

  %i[create? edit? new? show? update?].each do |action|
    permissions(action) do
      it 'grants access to admins only' do
        expect(policy).to permit(build(:admin), InternalUser.new)
        %i[external_user teacher].each do |factory_name|
          expect(policy).not_to permit(create(factory_name), InternalUser.new)
        end
      end
    end
  end

  permissions :index? do
    it 'grants access to admins and teachers only' do
      expect(policy).not_to permit(build(:external_user), InternalUser.new)
      %i[admin teacher].each do |factory_name|
        expect(policy).to permit(create(factory_name), InternalUser.new)
      end
    end
  end

  permissions :destroy? do
    context 'with an admin user' do
      it 'grants access to no one' do
        %i[admin external_user teacher].each do |factory_name|
          expect(policy).not_to permit(create(factory_name), build(:admin))
        end
      end
    end

    context 'with a non-admin user' do
      it 'grants access to admins only' do
        expect(policy).to permit(build(:admin), InternalUser.new)
        %i[external_user teacher].each do |factory_name|
          expect(policy).not_to permit(create(factory_name), create(:teacher))
        end
      end
    end
  end
end
