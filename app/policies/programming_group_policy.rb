# frozen_string_literal: true

class ProgrammingGroupPolicy < ApplicationPolicy
  def new?
    everyone
  end

  def create?
    everyone
  end

  def stream_sync_editor?
    admin? || author_in_programming_group?
  end
end
