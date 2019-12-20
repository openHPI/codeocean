# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/bionic64"
  config.vm.provider "virtualbox" do |v|
    v.memory = 8192
    v.cpus = 2
  end
  config.vm.network "private_network", ip: "192.168.59.104"
  config.vm.network "forwarded_port", guest: 3035, host: 3035
  # config.vm.synced_folder "../data", "/vagrant_data"
  config.vm.provision "shell", path: "provision.sh", privileged: false
end
