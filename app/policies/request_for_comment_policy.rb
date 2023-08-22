# frozen_string_literal: true

class RequestForCommentPolicy < ApplicationPolicy
  def create?
    everyone
  end

  def show?
    admin? || author? || author_in_programming_group? || rfc_visibility
  end

  def destroy?
    admin?
  end

  def mark_as_solved?
    admin? || author? || author_in_programming_group?
  end

  def set_thank_you_note?
    admin? || author? || author_in_programming_group?
  end

  def clear_question?
    admin? || teacher_in_study_group?
  end

  def edit?
    admin?
  end

  def index?
    everyone
  end

  def my_comment_requests?
    everyone
  end

  def rfcs_with_my_comments?
    everyone
  end

  def rfc_visibility
    # The consumer with the most restricted visibility determines the visibility of the RfC
    case [@user.consumer.rfc_visibility, @record.author.consumer.rfc_visibility]
      # Only if both consumers allow learners to see all RfCs, the RfC is visible to the learner
      when %w[all all]
        everyone
      # At least one consumer limits the visibility to the consumer
      when %w[consumer all], %w[all consumer], %w[consumer consumer]
        @record.author.consumer == @user.consumer
      # At least one consumer limits the visibility to the study group
      when %w[study_group all], %w[all study_group], %w[study_group consumer], %w[consumer study_group], %w[study_group study_group]
        @record.submission.study_group.present? && @record.submission.study_group.id == @user.current_study_group_id
      else
        raise "Unknown RfC Visibility #{current_user.consumer.rfc_visibility}"
    end
  end

  class Scope < Scope
    def resolve
      if @user.admin?
        @scope.all
      else
        case @user.consumer.rfc_visibility
          when 'all'
            # We need to filter those RfCs where the visibility is more restricted than the `all` visibility.
            rfcs_with_users = @scope
              .joins('LEFT OUTER JOIN external_users ON request_for_comments.user_type = \'ExternalUser\' AND request_for_comments.user_id = external_users.id')
              .joins('LEFT OUTER JOIN internal_users ON request_for_comments.user_type = \'InternalUser\' AND request_for_comments.user_id = internal_users.id')

            rfcs_with_users.where(external_users: {consumer_id: Consumer.rfc_visibility_all})
              .or(rfcs_with_users.where(internal_users: {consumer_id: Consumer.rfc_visibility_all}))
          when 'consumer'
            # Since the `rfc_visibility` is set on a consumer level, we do not need to consider the `study_group` visibility here.
            # Therefore, those RfCs where the author is limited to study group RfCs definitely belong to another consumer.
            rfcs_with_users = @scope
              .joins('LEFT OUTER JOIN external_users ON request_for_comments.user_type = \'ExternalUser\' AND request_for_comments.user_id = external_users.id')
              .joins('LEFT OUTER JOIN internal_users ON request_for_comments.user_type = \'InternalUser\' AND request_for_comments.user_id = internal_users.id')

            rfcs_with_users.where(external_users: {consumer_id: @user.consumer.id})
              .or(rfcs_with_users.where(internal_users: {consumer_id: @user.consumer.id}))
          when 'study_group'
            # Since the `rfc_visibility` is already the most restricted visibility, we do not need to consider any other visibility here.
            @scope
              .joins(:submission)
              .where(submission: {study_group: @user.current_study_group_id})
          else
            @scope.none
        end
      end
    end
  end
end
