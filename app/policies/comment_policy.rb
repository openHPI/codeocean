# frozen_string_literal: true

class CommentPolicy < ApplicationPolicy
  REPORT_RECEIVER_CONFIGURED = CodeOcean::Config.new(:code_ocean).read.dig(:content_moderation, :report_emails).present?

  def create?
    show?
  end

  def show?
    Pundit.policy(@user, @record.request_for_comment).show? && everyone
  end

  %i[destroy? update? edit?].each do |action|
    define_method(action) { admin? || author? || teacher_in_study_group? }
  end

  def index?
    everyone
  end

  def report?
    REPORT_RECEIVER_CONFIGURED && show? && !author?
  end
end
