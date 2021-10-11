# frozen_string_literal: true

class Runner::Strategy
  def initialize(_runner_id, environment)
    @execution_environment = environment
  end

  def self.config
    raise NotImplementedError
  end

  def self.sync_environment(_environment)
    raise NotImplementedError
  end

  def self.request_from_management(_environment)
    raise NotImplementedError
  end

  def destroy_at_management
    raise NotImplementedError
  end

  def copy_files(_files)
    raise NotImplementedError
  end

  def attach_to_execution(_command)
    raise NotImplementedError
  end

  def websocket_header
    raise NotImplementedError
  end
end
