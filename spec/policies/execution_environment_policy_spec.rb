require 'rails_helper'

describe ExecutionEnvironmentPolicy do
  subject { described_class }

  let(:execution_environment) { FactoryBot.build(:ruby) }

  [:create?, :index?, :new?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(subject).to permit(FactoryBot.build(:admin), execution_environment)
      end

      it 'grants access to teachers' do
        expect(subject).to permit(FactoryBot.build(:teacher), execution_environment)
      end

      it 'does not grant access to external users' do
        expect(subject).not_to permit(FactoryBot.build(:external_user), execution_environment)
      end
    end
  end

  [:execute_command?, :shell?, :statistics?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(subject).to permit(FactoryBot.build(:admin), execution_environment)
      end

      it 'grants access to authors' do
        expect(subject).to permit(execution_environment.author, execution_environment)
      end

      it 'does not grant access to all other users' do
        [:external_user, :teacher].each do |factory_name|
          expect(subject).not_to permit(FactoryBot.build(factory_name), execution_environment)
        end
      end
    end
  end

  [:destroy?, :edit?, :show?, :update?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(subject).to permit(FactoryBot.build(:admin), execution_environment)
      end

      it 'does not grant access to authors' do
        expect(subject).not_to permit(execution_environment.author, execution_environment)
      end

      it 'does not grant access to all other users' do
        [:external_user, :teacher].each do |factory_name|
          expect(subject).not_to permit(FactoryBot.build(factory_name), execution_environment)
        end
      end
    end
  end
end
