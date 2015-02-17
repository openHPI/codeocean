namespace :docker do
  desc 'Remove all Docker containers and dangling Docker images (using the CLI)'
  task :clean_up do
    `test -n "$(docker ps --all --quiet)" && docker rm --force $(docker ps --all --quiet)`
    `test -n "docker images --filter dangling=true --quiet" && docker rmi $(docker images --filter dangling=true --quiet)`
  end

  desc 'List all installed Docker images'
  task images: :environment do
    puts DockerClient.image_tags
  end

  desc 'Pull all Docker images referenced by execution environments'
  task pull: :environment do
    ExecutionEnvironment.all.map(&:docker_image).each do |docker_image|
      puts "Pulling #{docker_image}..."
      DockerClient.pull(docker_image)
    end
  end
end
