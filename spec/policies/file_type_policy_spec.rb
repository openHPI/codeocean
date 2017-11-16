require 'rails_helper'

describe FileTypePolicy do
  subject { described_class }

  let(:file_type) { FactoryBot.build(:dot_rb) }

  [:create?, :index?, :new?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(subject).to permit(FactoryBot.build(:admin), file_type)
      end

      it 'grants access to teachers' do
        expect(subject).to permit(FactoryBot.build(:teacher), file_type)
      end

      it 'does not grant access to external users' do
        expect(subject).not_to permit(FactoryBot.build(:external_user), file_type)
      end
    end
  end

  [:destroy?, :edit?, :show?, :update?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(subject).to permit(FactoryBot.build(:admin), file_type)
      end

      it 'grants access to authors' do
        expect(subject).to permit(file_type.author, file_type)
      end

      it 'does not grant access to all other users' do
        [:external_user, :teacher].each do |factory_name|
          expect(subject).not_to permit(FactoryBot.build(factory_name), file_type)
        end
      end
    end
  end
end
