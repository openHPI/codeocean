# frozen_string_literal: true

class ErrorTemplatePolicy < AdminOnlyPolicy
  %i[index? show?].each do |action|
    define_method(action) { admin? || teacher? }
  end

  def add_attribute?
    admin?
  end

  def remove_attribute?
    admin?
  end
end
