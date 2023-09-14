# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProgrammingGroupPolicy do
  subject(:policy) { described_class }

  let(:programming_group) { build(:programming_group) }

  %i[index? destroy? show? edit? update?].each do |action|
    permissions(action) do
      it 'grants access to admins only' do
        expect(policy).to permit(create(:admin), programming_group)
        %i[external_user teacher].each do |factory_name|
          expect(policy).not_to permit(create(factory_name), programming_group)
        end
      end
    end
  end

  %i[new? create?].each do |action|
    permissions(action) do
      it 'grants access to everyone' do
        %i[external_user teacher admin].each do |factory_name|
          expect(policy).to permit(create(factory_name), programming_group)
        end
      end
    end

    permissions(:stream_sync_editor?) do
      it 'grants access to admins' do
        expect(policy).to permit(create(:admin), programming_group)
      end

      it 'grants access to members of the programming group' do
        programming_group.users do |user|
          expect(policy).to permit(user, programming_group)
        end
      end

      it 'does not grant access to someone who is not a member of the programming group' do
        expect(policy).not_to permit(create(:external_user), programming_group)
      end
    end
  end
end
