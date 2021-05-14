# frozen_string_literal: true

module Silencer
  def silenced
    @stdout = $stdout
    $stdout = Tempfile.new('stdout')
    yield if block_given?
  ensure
    $stdout.close
    $stdout.unlink
    $stdout = @stdout
  end
end
