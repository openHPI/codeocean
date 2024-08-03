# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExecutionEnvironmentPolicy do
  subject(:policy) { described_class }

  let(:execution_environment) { build(:ruby) }

  %i[index? execute_command? shell? list_files? show? download_arbitrary_file?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(policy).to permit(build(:admin), execution_environment)
      end

      it 'grants access to teachers' do
        expect(policy).to permit(create(:teacher), execution_environment)
      end

      it 'does not grant access to external users' do
        expect(policy).not_to permit(build(:external_user), execution_environment)
      end
    end
  end

  %i[statistics? sync_to_runner_management?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(policy).to permit(build(:admin), execution_environment)
      end

      it 'grants access to authors' do
        expect(policy).to permit(execution_environment.author, execution_environment)
      end

      it 'does not grant access to all other users' do
        %i[external_user teacher].each do |factory_name|
          expect(policy).not_to permit(create(factory_name), execution_environment)
        end
      end
    end
  end

  %i[destroy? edit? update? new? create?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(policy).to permit(build(:admin), execution_environment)
      end

      it 'does not grant access to authors' do
        expect(policy).not_to permit(execution_environment.author, execution_environment)
      end

      it 'does not grant access to all other users' do
        %i[external_user teacher].each do |factory_name|
          expect(policy).not_to permit(create(factory_name), execution_environment)
        end
      end
    end
  end

  permissions :sync_all_to_runner_management? do
    it 'grants access to the admin' do
      expect(policy).to permit(build(:admin))
    end

    it 'does not grant access to all other users' do
      %i[external_user teacher].each do |factory_name|
        expect(policy).not_to permit(create(factory_name))
      end
    end
  end
end
