# frozen_string_literal: true

class ExecutionEnvironmentPolicy < AdminOnlyPolicy
  # download_arbitrary_file? is used in the live_streams_controller.rb
  %i[index? execute_command? shell? list_files? show? download_arbitrary_file?].each do |action|
    define_method(action) { admin? || teacher? }
  end

  %i[statistics? sync_to_runner_management?].each do |action|
    define_method(action) { admin? || author? }
  end

  def sync_all_to_runner_management?
    admin?
  end
end
