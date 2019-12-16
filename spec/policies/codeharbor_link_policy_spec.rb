require 'rails_helper'

describe CodeharborLinkPolicy do
  subject(:policy) { described_class }

  let(:codeharbor_link) { FactoryBot.create(:codeharbor_link) }

  %i[index? show?].each do |action|
    permissions(action) do
      it 'does not grant access any user' do
        %i[external_user teacher admin].each do |factory_name|
          expect(policy).not_to permit(FactoryBot.create(factory_name), codeharbor_link)
        end
      end
    end
  end

  %i[new? create?].each do |action|
    permissions(action) do
      it 'grants access to teachers' do
        %i[teacher admin].each do |factory_name|
          expect(policy).to permit(FactoryBot.create(factory_name), codeharbor_link)
        end
      end

      it 'does not grant access to all other users' do
        expect(policy).not_to permit(FactoryBot.create(:external_user), codeharbor_link)
      end
    end
  end

  %i[destroy? edit? update?].each do |action|
    permissions(action) do
      it 'grants access to the owner of the link' do
        expect(policy).to permit(codeharbor_link.user, codeharbor_link)
      end

      it 'does not grant access to arbitrary users' do
        %i[external_user admin teacher].each do |factory_name|
          expect(policy).not_to permit(FactoryBot.create(factory_name), codeharbor_link)
        end
      end
    end
  end
end
