# frozen_string_literal: true

class EventPolicy < AdminOnlyPolicy
  def create?
    everyone
  end
end
