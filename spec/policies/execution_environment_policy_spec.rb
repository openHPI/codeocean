# frozen_string_literal: true

require 'rails_helper'

describe ExecutionEnvironmentPolicy do
  subject(:policy) { described_class }

  let(:execution_environment) { FactoryBot.build(:ruby) }

  [:index?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(policy).to permit(FactoryBot.build(:admin), execution_environment)
      end

      it 'grants access to teachers' do
        expect(policy).to permit(FactoryBot.build(:teacher), execution_environment)
      end

      it 'does not grant access to external users' do
        expect(policy).not_to permit(FactoryBot.build(:external_user), execution_environment)
      end
    end
  end

  %i[execute_command? shell? statistics? show?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(policy).to permit(FactoryBot.build(:admin), execution_environment)
      end

      it 'grants access to authors' do
        expect(policy).to permit(execution_environment.author, execution_environment)
      end

      it 'does not grant access to all other users' do
        %i[external_user teacher].each do |factory_name|
          expect(policy).not_to permit(FactoryBot.build(factory_name), execution_environment)
        end
      end
    end
  end

  %i[destroy? edit? update? new? create?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(policy).to permit(FactoryBot.build(:admin), execution_environment)
      end

      it 'does not grant access to authors' do
        expect(policy).not_to permit(execution_environment.author, execution_environment)
      end

      it 'does not grant access to all other users' do
        %i[external_user teacher].each do |factory_name|
          expect(policy).not_to permit(FactoryBot.build(factory_name), execution_environment)
        end
      end
    end
  end

  permissions(:synchronize_all_to_poseidon?) do
    it 'grants access to the admin' do
      expect(policy).to permit(FactoryBot.build(:admin))
    end

    shared_examples 'it does not grant access' do |user|
      it "does not grant access to a user with role #{user.role}" do
        expect(policy).not_to permit(user)
      end
    end

    %i[teacher external_user].each do |user|
      include_examples 'it does not grant access', FactoryBot.build(user)
    end
  end
end
