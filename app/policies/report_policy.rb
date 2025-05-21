# frozen_string_literal: true

class ReportPolicy < ApplicationPolicy
  def create?
    @user && [RequestForComment, Comment].include?(@record.class)
  end
end
