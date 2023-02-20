# frozen_string_literal: true

class RequestForCommentPolicy < ApplicationPolicy
  def create?
    everyone
  end

  def show?
    admin? || rfc_visibility
  end

  def destroy?
    admin?
  end

  def mark_as_solved?
    admin? || (author? && rfc_visibility)
  end

  def set_thank_you_note?
    admin? || (author? && rfc_visibility)
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
    case @user.consumer.rfc_visibility
      when 'all'
        everyone
      when 'consumer'
        @record.author.consumer == @user.consumer
      when 'study_group'
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
            @scope.all
          when 'consumer'
            rfcs_with_users = @scope
              .joins('LEFT OUTER JOIN external_users ON request_for_comments.user_type = \'ExternalUser\' AND request_for_comments.user_id = external_users.id')
              .joins('LEFT OUTER JOIN internal_users ON request_for_comments.user_type = \'InternalUser\' AND request_for_comments.user_id = internal_users.id')

            rfcs_with_users.where(external_users: {consumer_id: @user.consumer.id})
              .or(rfcs_with_users.where(internal_users: {consumer_id: @user.consumer.id}))
          when 'study_group'
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
