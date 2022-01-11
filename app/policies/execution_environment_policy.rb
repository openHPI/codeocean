# frozen_string_literal: true

class ExecutionEnvironmentPolicy < AdminOnlyPolicy
  %i[execute_command? shell? statistics? show? sync_to_runner_management?].each do |action|
    define_method(action) { admin? || author? }
  end

  [:index?].each do |action|
    define_method(action) { admin? || teacher? }
  end

  def sync_all_to_runner_management?
    admin?
  end
end
