IMAGE = Docker::Image.new(Docker::Connection.new('http://example.org', {}), 'id' => SecureRandom.hex)

RSpec.configure do |config|
  config.before(:each) do |example|
    unless example.metadata[:docker]
      allow(DockerClient).to receive(:check_availability!).and_return(true)
      allow(DockerClient).to receive(:image_tags).and_return([IMAGE])
      allow_any_instance_of(DockerClient).to receive(:execute_command).and_return({})
      allow_any_instance_of(DockerClient).to receive(:find_image_by_tag).and_return(IMAGE)
      allow_any_instance_of(ExecutionEnvironment).to receive(:working_docker_image?)
    end
  end
end
