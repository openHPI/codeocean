# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = 'ubuntu/jammy64'
  config.vm.provider 'virtualbox' do |v|
    v.memory = 4096
    v.cpus = 4
  end

  # CodeOcean Rails app
  config.vm.network 'forwarded_port',
    host_ip: ENV.fetch('LISTEN_ADDRESS', '127.0.0.1'),
    host: 7000,
    guest: 7000

  # Webpack Dev Server
  config.vm.network 'forwarded_port',
    host_ip: ENV.fetch('LISTEN_ADDRESS', '127.0.0.1'),
    host: 3035,
    guest: 3035

  # Poseidon
  config.vm.network 'forwarded_port',
    host_ip: ENV.fetch('LISTEN_ADDRESS', '127.0.0.1'),
    host: 7200,
    guest: 7200

  # Nomad UI
  config.vm.network 'forwarded_port',
    host_ip: ENV.fetch('LISTEN_ADDRESS', '127.0.0.1'),
    host: 4646,
    guest: 4646

  config.vm.synced_folder '.', '/home/vagrant/codeocean'
  config.vm.synced_folder '../poseidon', '/home/vagrant/poseidon'
  config.vm.provision 'shell', path: 'provision/provision.vagrant.sh', privileged: false
end
