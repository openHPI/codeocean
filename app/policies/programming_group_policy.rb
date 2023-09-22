# frozen_string_literal: true

class ProgrammingGroupPolicy < ApplicationPolicy
  def new?
    everyone
  end

  def create?
    everyone
  end

  def stream_sync_editor?
    # A programming group needs to exist for the user to be able to stream the synchronized editor.
    return false if @record.blank?

    admin? || author_in_programming_group?
  end
end
