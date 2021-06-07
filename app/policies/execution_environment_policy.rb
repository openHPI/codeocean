# frozen_string_literal: true

class ExecutionEnvironmentPolicy < AdminOnlyPolicy
  %i[execute_command? shell? statistics? show?].each do |action|
    define_method(action) { admin? || author? }
  end

  [:index?].each do |action|
    define_method(action) { admin? || teacher? }
  end

  def synchronize_all_to_poseidon?
    admin?
  end
end
