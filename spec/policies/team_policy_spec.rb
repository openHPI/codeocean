require 'rails_helper'

describe TeamPolicy do
  subject { TeamPolicy }

  let(:team) { FactoryGirl.build(:team) }

  [:create?, :index?, :new?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(subject).to permit(FactoryGirl.build(:admin), team)
      end

      it 'grants access to teachers' do
        expect(subject).to permit(FactoryGirl.build(:teacher), team)
      end

      it 'does not grant access to external users' do
        expect(subject).not_to permit(FactoryGirl.build(:external_user), team)
      end
    end
  end

  [:destroy?, :edit?, :show?, :update?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(subject).to permit(FactoryGirl.build(:admin), team)
      end

      it 'grants access to members' do
        expect(subject).to permit(team.members.last, team)
      end

      it 'does not grant access to all other users' do
        [:external_user, :teacher].each do |factory_name|
          expect(subject).not_to permit(FactoryGirl.build(factory_name), team)
        end
      end
    end
  end
end
