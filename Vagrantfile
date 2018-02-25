# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.provider "virtualbox" do |v|
    v.memory = 8192
  end
  config.vm.network "private_network", ip: "192.168.59.104"
  # config.vm.synced_folder "../data", "/vagrant_data"
  config.vm.provision "shell", path: "provision.sh", privileged: false
end
