# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CommentPolicy do
  let(:user_types) { %i[learner teacher admin] }

  permissions :create?, :show?, :index? do
    let(:comment) { build_stubbed(:comment) }

    it 'grants access to all user types' do
      user_types.each do |user_type|
        expect(described_class).to permit(build_stubbed(user_type), comment)
      end
    end
  end

  permissions :destroy?, :update?, :edit? do
    let(:comment) { build_stubbed(:comment) }

    it 'grants access to the author' do
      expect(described_class).to permit(comment.user, comment)
    end

    it 'grants no access to other learners' do
      expect(described_class).not_to permit(build_stubbed(:learner), comment)
    end

    it 'grants no access to teachers not in the same study group' do
      expect(described_class).not_to permit(build_stubbed(:teacher), comment)
    end

    it 'grants access to teachers in the same study group' do
      comment = create(:comment)
      teacher = create(:teacher, study_groups: [comment.submission.study_group])

      expect(described_class).to permit(teacher, comment)
    end

    it 'grants access to admins' do
      expect(described_class).to permit(build_stubbed(:admin), comment)
    end
  end
end
