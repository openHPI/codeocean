class ErrorTemplatePolicy < AdminOnlyPolicy
  def add_attribute?
    admin?
  end

  def remove_attribute?
    admin?
  end
end
