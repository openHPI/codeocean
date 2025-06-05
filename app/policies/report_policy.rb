# frozen_string_literal: true

class ReportPolicy < ApplicationPolicy
  def show?
    receiver_available? && reportable_content? && reports_other_user?
  end

  def create?
    receiver_available? && reportable_content? && reports_other_user?
  end

  private

  def reportable_content?
    [RequestForComment, Comment].include?(@record.class)
  end

  def reports_other_user?
    @record.user != @user
  end

  def receiver_available?
    ReportMailer.default_params.fetch(:to).present?
  end
end
