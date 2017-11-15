require 'rails_helper'

describe ErrorPolicy do
  subject { described_class }

  let(:error) { FactoryBot.build(:error) }

  [:create?, :index?, :new?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(subject).to permit(FactoryBot.build(:admin), error)
      end

      it 'grants access to teachers' do
        expect(subject).to permit(FactoryBot.build(:teacher), error)
      end

      it 'does not grant access to external users' do
        expect(subject).not_to permit(FactoryBot.build(:external_user), error)
      end
    end
  end

  [:destroy?, :edit?, :show?, :update?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(subject).to permit(FactoryBot.build(:admin), error)
      end

      it 'grants access to authors' do
        expect(subject).to permit(error.execution_environment.author, error)
      end

      it 'does not grant access to all other users' do
        [:external_user, :teacher].each do |factory_name|
          expect(subject).not_to permit(FactoryBot.build(factory_name), error)
        end
      end
    end
  end
end
