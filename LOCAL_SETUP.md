Local Setup with Vagrant
==========

## Install prerequisites
Install Vagrant - https://www.vagrantup.com/docs/installation/  
Install VirtualBox - https://www.virtualbox.org/wiki/Downloads

## Install and setup
### Clone repository   
Create a local codeOceanRoot:   mkdir /path/to/CodeOcean  ==> codeOceanRoot = /path/to/CodeOcean   
Clone Repository (https://github.com/openHPI/codeocean) to codeOceanRoot  
cd codeOceanRoot  

### Get Vagrant base image 
vagrant box add ubuntu/trusty64  
vagrant up  

### Trouble shooting 
ln -s /etc/nginx/sites-available/code_ocean /etc/nginx/sites-enabled <= Failed (no such directory)  

vagrant ssh   
sudo apt-get install nginx  
sudo ln -s /etc/nginx/sites-available/code_ocean /etc/nginx/sites-enabled  

### Make docker daemon useable without sudo
# Infos taken from: http://askubuntu.com/questions/477551/how-can-i-use-docker-without-sudo

sudo groupadd docker
sudo gpasswd -a ${USER} docker
sudo service docker restart
newgrp docker

### Start server
vagrant ssh  
cd /vagrant  
rails s -p 3000  

### Login to CodeOcean
192.168.59.104:3000  
admin@example.org:admin
