require 'rails_helper'

describe ExecutionEnvironmentPolicy do
  subject { ExecutionEnvironmentPolicy }

  let(:execution_environment) { FactoryGirl.build(:ruby) }

  [:create?, :index?, :new?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(subject).to permit(FactoryGirl.build(:admin), execution_environment)
      end

      it 'grants access to teachers' do
        expect(subject).to permit(FactoryGirl.build(:teacher), execution_environment)
      end

      it 'does not grant access to external users' do
        expect(subject).not_to permit(FactoryGirl.build(:external_user), execution_environment)
      end
    end
  end

  [:destroy?, :edit?, :execute_command?, :shell?, :show?, :update?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(subject).to permit(FactoryGirl.build(:admin), execution_environment)
      end

      it 'grants access to authors' do
        expect(subject).to permit(execution_environment.author, execution_environment)
      end

      it 'does not grant access to all other users' do
        [:external_user, :teacher].each do |factory_name|
          expect(subject).not_to permit(FactoryGirl.build(factory_name), execution_environment)
        end
      end
    end
  end
end
