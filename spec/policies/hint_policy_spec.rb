require 'rails_helper'

describe HintPolicy do
  subject { described_class }

  let(:hint) { FactoryBot.build(:ruby_no_method_error) }

  [:create?, :index?, :new?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(subject).to permit(FactoryBot.build(:admin), hint)
      end

      it 'grants access to teachers' do
        expect(subject).to permit(FactoryBot.build(:teacher), hint)
      end

      it 'does not grant access to external users' do
        expect(subject).not_to permit(FactoryBot.build(:external_user), hint)
      end
    end
  end

  [:destroy?, :edit?, :show?, :update?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(subject).to permit(FactoryBot.build(:admin), hint)
      end

      it 'grants access to authors' do
        expect(subject).to permit(hint.execution_environment.author, hint)
      end

      it 'does not grant access to all other users' do
        [:external_user, :teacher].each do |factory_name|
          expect(subject).not_to permit(FactoryBot.build(factory_name), hint)
        end
      end
    end
  end
end
