# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmissionPolicy do
  subject(:policy) { described_class }

  permissions :create? do
    it 'grants access to anyone' do
      %i[admin external_user teacher].each do |factory_name|
        expect(policy).to permit(create(factory_name), Submission.new)
      end
    end
  end

  %i[download? download_file? download_submission_file? render_file? run? score? show? statistics? stop? test? insights? finalize?].each do |action|
    permissions(action) do
      let(:exercise) { build(:math) }
      let(:group_author) { build(:external_user) }
      let(:other_group_author) { build(:external_user) }

      it 'grants access to admins' do
        expect(policy).to permit(build(:admin), Submission.new)
      end

      it 'grants access to authors' do
        contributor = create(:external_user)
        expect(policy).to permit(contributor, build(:submission, exercise:, contributor:))
      end

      it 'grants access to other authors of the programming group' do
        contributor = build(:programming_group, exercise:, users: [group_author, other_group_author])
        expect(policy).to permit(group_author, build(:submission, exercise:, contributor:))
        expect(policy).to permit(other_group_author, build(:submission, exercise:, contributor:))
      end
    end
  end

  permissions :index? do
    it 'grants access to admins only' do
      expect(policy).to permit(build(:admin), Submission.new)
      %i[external_user teacher].each do |factory_name|
        expect(policy).not_to permit(create(factory_name), Submission.new)
      end
    end
  end
end
