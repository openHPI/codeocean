CONTAINER = Docker::Container.send(:new, Docker::Connection.new('http://example.org', {}), 'id' => SecureRandom.hex)
IMAGE = Docker::Image.new(Docker::Connection.new('http://example.org', {}), 'id' => SecureRandom.hex, 'RepoTags' => [FactoryBot.attributes_for(:ruby)[:docker_image]])

RSpec.configure do |config|
  config.before(:each) do |example|
    unless example.metadata[:docker]
      allow(DockerClient).to receive(:check_availability!).and_return(true)
      allow(DockerClient).to receive(:create_container).and_return(CONTAINER)
      allow(DockerClient).to receive(:find_image_by_tag).and_return(IMAGE)
      allow(DockerClient).to receive(:image_tags).and_return([IMAGE])
      allow(DockerClient).to receive(:local_workspace_path).and_return(Pathname.new('/tmp'))
      allow_any_instance_of(DockerClient).to receive(:send_command).and_return({})
      allow_any_instance_of(ExecutionEnvironment).to receive(:working_docker_image?)
    end
  end

  config.after(:suite) do
    FileUtils.rm_rf(Rails.root.join('tmp', 'files', 'test'))
    `which docker && test -n "$(docker ps --all --quiet)" && docker rm --force $(docker ps --all --quiet)`
  end
end
