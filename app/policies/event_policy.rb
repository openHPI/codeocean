class EventPolicy < AdminOnlyPolicy

  def create?
    everyone
  end

end
