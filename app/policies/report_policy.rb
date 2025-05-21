# frozen_string_literal: true

class ReportPolicy < ApplicationPolicy
  def show?
    reciever_awalible? && @user
  end

  def create?
    reciever_awalible? && @user && [RequestForComment, Comment].include?(@record.class)
  end

  private

  def reciever_awalible?
    ReportMailer.default_params.fetch(:to).present?
  end
end
