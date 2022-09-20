# frozen_string_literal: true

require 'rails_helper'

describe ExternalUserPolicy do
  subject(:policy) { described_class }

  %i[create? destroy? edit? new? show? update?].each do |action|
    permissions(action) do
      it 'grants access to admins only' do
        expect(policy).to permit(build(:admin), ExternalUser.new)
        %i[external_user teacher].each do |factory_name|
          expect(policy).not_to permit(create(factory_name), ExternalUser.new)
        end
      end
    end
  end

  permissions :index? do
    it 'grants access to admins and teachers only' do
      expect(policy).to permit(create(:admin), ExternalUser.new)
      expect(policy).to permit(create(:teacher), ExternalUser.new)
      [:external_user].each do |factory_name|
        expect(policy).not_to permit(create(factory_name), ExternalUser.new)
      end
    end
  end
end
