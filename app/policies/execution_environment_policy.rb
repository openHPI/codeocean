# frozen_string_literal: true

class ExecutionEnvironmentPolicy < AdminOnlyPolicy
  # download_arbitrary_file? is used in the live_streams_controller.rb
  %i[execute_command? shell? list_files? statistics? show? sync_to_runner_management? download_arbitrary_file?].each do |action|
    define_method(action) { admin? || author? }
  end

  [:index?].each do |action|
    define_method(action) { admin? || teacher? }
  end

  def sync_all_to_runner_management?
    admin?
  end
end
