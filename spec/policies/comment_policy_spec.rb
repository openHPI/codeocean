# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CommentPolicy do
  let(:user_types) { %i[learner teacher admin] }

  permissions :index? do
    let(:comment) { build_stubbed(:comment) }

    it 'grants access to all user types' do
      user_types.each do |user_type|
        expect(described_class).to permit(build_stubbed(user_type), comment)
      end
    end
  end

  permissions :create?, :show? do
    let(:comment) { build_stubbed(:comment) }

    it 'grants access to all user types' do
      user_types.each do |user_type|
        expect(described_class).to permit(build_stubbed(user_type), comment)
      end
    end

    context 'without access to the RfC' do
      let(:learner) { build_stubbed(:learner) }
      let(:rfc_policy) { instance_double(RequestForCommentPolicy, show?: false) }

      before do
        allow(RequestForCommentPolicy).to receive(:new)
          .with(learner, comment.request_for_comment)
          .and_return(rfc_policy)
      end

      it 'does not grant access' do
        expect(described_class).not_to permit(learner, comment)
      end
    end
  end

  permissions :destroy?, :update?, :edit? do
    let(:comment) { build_stubbed(:comment) }

    it 'grants access to the author' do
      expect(described_class).to permit(comment.user, comment)
    end

    it 'does not grant access to other learners' do
      expect(described_class).not_to permit(build_stubbed(:learner), comment)
    end

    it 'does not grant access to teachers not in the same study group' do
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

  permissions :report? do
    let(:comment) { build_stubbed(:comment) }

    before do
      stub_const('CommentPolicy::REPORT_RECEIVER_CONFIGURED', reports_enabled)
    end

    context 'when content moderation is enabled' do
      let(:reports_enabled) { true }

      it 'grants access to all user types' do
        user_types.each do |user_type|
          expect(described_class).to permit(build_stubbed(user_type), comment)
        end
      end

      it 'does not grants access to the author' do
        expect(described_class).not_to permit(comment.user, comment)
      end

      it 'does not grant access to users who have no access to the RfC' do
        learner = build_stubbed(:learner)
        rfc_policy = instance_double(RequestForCommentPolicy, show?: false)
        allow(RequestForCommentPolicy).to receive(:new).with(learner, comment.request_for_comment)
          .and_return(rfc_policy)

        expect(described_class).not_to permit(learner, comment)
      end
    end

    context 'when content moderation is disabled' do
      let(:reports_enabled) { false }

      it 'does not grant access to all user types' do
        user_types.each do |user_type|
          expect(described_class).not_to permit(build_stubbed(user_type), comment)
        end
      end
    end
  end
end
