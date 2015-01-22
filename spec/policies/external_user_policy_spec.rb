require 'rails_helper'

describe ExternalUserPolicy do
  subject { ExternalUserPolicy }

  [:create?, :destroy?, :edit?, :index?, :new?, :show?, :update?].each do |action|
    permissions(action) do
      it 'grants access to admins only' do
        expect(subject).to permit(FactoryGirl.build(:admin), ExternalUser.new)
        [:external_user, :teacher].each do |factory_name|
          expect(subject).not_to permit(FactoryGirl.build(factory_name), ExternalUser.new)
        end
      end
    end
  end
end
