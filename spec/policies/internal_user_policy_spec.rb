require 'rails_helper'

describe InternalUserPolicy do
  subject { InternalUserPolicy }

  [:create?, :edit?, :index?, :new?, :show?, :update?].each do |action|
    permissions(action) do
      it 'grants access to admins only' do
        expect(subject).to permit(FactoryGirl.build(:admin), InternalUser.new)
        [:external_user, :teacher].each do |factory_name|
          expect(subject).not_to permit(FactoryGirl.build(factory_name), InternalUser.new)
        end
      end
    end
  end

  permissions :destroy? do
    context 'with an admin user' do
      it 'grants access to no one' do
        [:admin, :external_user, :teacher].each do |factory_name|
          expect(subject).not_to permit(FactoryGirl.build(factory_name), FactoryGirl.build(:admin))
        end
      end
    end

    context 'with a non-admin user' do
      it 'grants access to admins only' do
        expect(subject).to permit(FactoryGirl.build(:admin), InternalUser.new)
        [:external_user, :teacher].each do |factory_name|
          expect(subject).not_to permit(FactoryGirl.build(factory_name), FactoryGirl.build(:teacher))
        end
      end
    end
  end
end
