# frozen_string_literal: true

# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = 'ubuntu/focal64'
  config.vm.provider 'virtualbox' do |v|
    v.memory = 4096
    v.cpus = 4
  end
  config.vm.network 'forwarded_port',
    host_ip: ENV.fetch('LISTEN_ADDRESS', '127.0.0.1'),
    host: 7000,
    guest: 7000
  config.vm.synced_folder '.', '/home/vagrant/codeocean'
  config.vm.synced_folder '../dockercontainerpool', '/home/vagrant/dockercontainerpool'
  config.vm.provision 'shell', path: 'provision/provision.vagrant.sh', privileged: false
end
