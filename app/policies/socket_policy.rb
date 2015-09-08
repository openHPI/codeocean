class SocketPolicy < ApplicationPolicy
  def docker?
    everyone
  end
end
