# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProgrammingGroupPolicy do
  subject(:policy) { described_class }

  let(:study_group) { create(:study_group) }
  let(:programming_group_members) { create_list(:external_user, 2, study_groups: [study_group]) }
  let(:programming_group) { create(:programming_group, users: programming_group_members) }

  before do
    create(:submission, contributor: programming_group, study_group:)
  end

  permissions :index? do
    it 'grants access to admins' do
      expect(policy).to permit(create(:admin), programming_group)
    end

    it 'grants access to teachers' do
      expect(policy).to permit(create(:teacher), programming_group)
    end

    it 'does not grant access to external users' do
      expect(policy).not_to permit(create(:external_user), programming_group)
    end
  end

  permissions :show? do
    it 'grants access to admins' do
      expect(policy).to permit(create(:admin), programming_group)
    end

    it 'grants access to teachers of the same study group' do
      expect(policy).to permit(create(:teacher, study_groups: [study_group]), programming_group)
    end

    it 'does not grant access to other teachers' do
      expect(policy).not_to permit(create(:teacher), programming_group)
    end

    it 'does not grant access to external users' do
      expect(policy).not_to permit(create(:external_user), programming_group)
    end
  end

  %i[edit? update?].each do |action|
    permissions(action) do
      it 'grants access to admins' do
        expect(policy).to permit(create(:admin), programming_group)
      end

      it 'does not grant access to teachers of the same study group' do
        expect(policy).not_to permit(create(:teacher, study_groups: [study_group]), programming_group)
      end

      it 'does not grant access to other teachers' do
        expect(policy).not_to permit(create(:teacher), programming_group)
      end

      it 'does not grant access to external users' do
        expect(policy).not_to permit(create(:external_user), programming_group)
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

  permissions :destroy? do
    it 'grants access to admins' do
      expect(policy).to permit(create(:admin), programming_group)
    end

    it 'does not grant access to teachers of the same study group' do
      expect(policy).not_to permit(create(:teacher, study_groups: [study_group]), programming_group)
    end

    it 'does not grant access to other teachers' do
      expect(policy).not_to permit(create(:teacher), programming_group)
    end

    it 'does not grant access to external users' do
      expect(policy).not_to permit(create(:external_user), programming_group)
    end
  end
end
