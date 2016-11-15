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
(sometimes, particularly if VirtualBox is running under Windows as the host sysstem, parts of the provision script are) not executed.
vagrant up does not show error messages but later on the trouble starts.

ln -s /etc/nginx/sites-available/code_ocean /etc/nginx/sites-enabled <= Failed (no such directory)  

#### Make docker daemon useable without sudo
Infos taken from: http://askubuntu.com/questions/477551/how-can-i-use-docker-without-sudo

vagrant ssh 
sudo groupadd docker
sudo gpasswd -a ${USER} docker
sudo service docker restart
newgrp docker

apt-get install nginx  
ln -s /etc/nginx/sites-available/code_ocean /etc/nginx/sites-enabled  

#### If ruby version needs to be updated (as provision.sh is not up-to-date :( )
Infos taken from: http://stackoverflow.com/questions/26242712/installing-rvm-getting-error-there-was-an-error23

vagrant ssh
rvm group add rvm "$USER"

logout and login again
rvm fix-permissions (not necessarily required)
rvm install (requested ruby version)

cd /vagrant
gem install bundler
bundle install

#### Pending migrations
vagrant ssh
cd /vagrant
rake db:migrate

#### Missing config files or anything else goes wrong
Check the according parts of the provision.sh file and try to re-run them directly in the vagrant VM.
All problems that have occurred resulted from a more restrictive rights management in the VMs that run under a Windows host system.

### Start server
vagrant ssh  
cd /vagrant  
rails s -p 3000  

### Login to CodeOcean
192.168.59.104:3000  
admin@example.org:admin
