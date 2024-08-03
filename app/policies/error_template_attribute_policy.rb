# frozen_string_literal: true

class ErrorTemplateAttributePolicy < AdminOnlyPolicy
  %i[index? show?].each do |action|
    define_method(action) { admin? || teacher? }
  end
end
