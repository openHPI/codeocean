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
rails s -p 3000 -b 0.0.0.0

### Login to CodeOcean
192.168.59.104:3000  
admin@example.org:admin

## Native setup (for macOS)

- Clone this repository:
  ```shell script
  git clone git@github.com:openHPI/codeocean.git
  ```
- Install PostgreSQL, start it and create a generic postgres user:
  ```shell script
  brew install postgresql
  brew services start postgresql
  createuser -s -r postgres
  ```
- Install [NVM](https://github.com/creationix/nvm) and node:
  ```shell script
  brew install nvm
  mkdir ~/.nvm
  nvm install --lts
  ```
- Add the following lines to your profile. (e.g., `~/.zshrc`):
  ```shell script
  # NVM
  export NVM_DIR=~/.nvm
  source $(brew --prefix nvm)/nvm.sh
  ```
- Install yarn:
  ```shell script
  brew install yarn --ignore-dependencies
  ```
- Install docker:
  ```shell script
  brew install docker
  open /Applications/Docker.app/
  ```
- Install nginx and adopt its config to forward requests to the **RAW** docker UNIX socket (see [this issue](https://github.com/docker/for-mac/issues/1662) for more details):
  ```shell script
  brew install nginx
  ```
  Edit `/usr/local/etc/nginx/nginx.conf`:
  1. Change the default port `8080` to `2376` (around line 36).
  2. Replace the `location /` with the following and (!) replace `<yourname>` with the output of `whoami`:
  ```editorconfig
  location / {
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header Host $host;
    proxy_set_header X-NginX-Proxy true;
  
    proxy_pass http://unix:/Usrers/<yourname>/Library/Containers/com.docker.docker/Data/docker.raw.sock;
    proxy_redirect off;
  
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
  }
  ```
  Now, start nginx:
  ```shell script
  brew services start nginx
  ```
- Install RVM and bundler:
  ```shell script
  gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
  curl -sSL https://get.rvm.io | bash -s stable --rails
  gem install bundler
  ```
- Install geckodriver and Firefox for Selenium:
  ```shell script
  brew install geckodriver
  brew cask install firefox
  ```
- Get a local copy of the config files:
  ```shell script
  for f in action_mailer.yml database.yml secrets.yml code_ocean.yml docker.yml.erb mnemosyne.yml
  do
    if [ ! -f config/$f ]
    then
      cp config/$f.example config/$f
    fi
  done
  ```
- Install gems and yarn files:
  ```shell script
  bundle install
  yarn install
  ```
- Setup your database:
  ```shell script
  rake db:create
  rake db:schema:load
  rake db:migrate
  rake db:seed
  ```
