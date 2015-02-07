module Silencer
  def silenced
    @stdout = $stdout
    $stdout = File.new(File.join('tmp', 'stdout'), 'w')
    yield if block_given?
    $stdout = @stdout
  end
end
