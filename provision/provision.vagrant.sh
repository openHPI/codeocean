#!/bin/bash

######## VERSION INFORMATION ########

postgres_version=14
node_version=14
ruby_version=2.7.6

########## INSTALL SCRIPT ###########

DISTRO="$(lsb_release -cs)"

# Disable any optimizations for comparing checksums.
# Otherwise, a hash collision might prevent apt to work correctly
# https://askubuntu.com/a/1242739
sudo mkdir -p /etc/gcrypt
echo all | sudo tee /etc/gcrypt/hwf.deny

# Prerequisites
sudo apt -qq update
sudo apt -qq -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common firefox firefox-geckodriver libpq-dev libicu-dev acl
sudo apt -qq -y upgrade

# PostgreSQL
curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
echo "deb https://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
sudo apt -qq update && sudo apt -qq install -y postgresql-client-$postgres_version postgresql-$postgres_version

sudo sed -i "/# TYPE/q" /etc/postgresql/$postgres_version/main/pg_hba.conf
sudo tee -a /etc/postgresql/$postgres_version/main/pg_hba.conf <<EOF
# code_ocean: drop access control
local all all trust
host  all all 127.0.0.1/32 trust
host  all all ::1/128 trust
EOF
sudo systemctl restart postgresql

# Install node
curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo apt-key add -
echo "deb https://deb.nodesource.com/node_$node_version.x $DISTRO main" | sudo tee /etc/apt/sources.list.d/nodesource.list
echo "deb-src https://deb.nodesource.com/node_$node_version.x $DISTRO main" | sudo tee -a /etc/apt/sources.list.d/nodesource.list
sudo apt -qq update && sudo apt -qq install -y nodejs

# yarn
curl -sSL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt -qq update && sudo apt -qq install -y yarn

# Docker
curl -sSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $DISTRO \
   stable"
sudo apt -qq update && sudo apt -qq -y install docker-ce docker-ce-cli containerd.io

sudo usermod -aG docker ${USER}

sudo tee -a /etc/docker/daemon.json <<EOF
{
        "userns-remap": "default"
}
EOF

sudo mkdir -p /etc/systemd/system/docker.service.d/
sudo tee -a /etc/systemd/system/docker.service.d/override.conf <<EOF
[Service]
# Empty line is required
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://127.0.0.1:2376
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker

# Pull example docker image
sudo docker pull openhpi/co_execenv_python:3.8

# RVM
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -
curl -sSL https://get.rvm.io | bash -s stable
source "/home/vagrant/.profile"

# ruby
rvm install $ruby_version
rvm use $ruby_version --default

# bundler
gem install bundler

######## CODEOCEAN INSTALL ##########
cd /home/vagrant/codeocean

# config
for f in action_mailer.yml database.yml secrets.yml docker.yml.erb mnemosyne.yml
do
  if [ ! -f config/$f ]
  then
    cp config/$f.example config/$f
  fi
done

# We want to use a preconfigured code_ocean.yml file which is using the DockerContainerPool
if [ ! -f config/code_ocean.yml ]
then
  cp provision/code_ocean.vagrant.yml config/code_ocean.yml
fi

# install dependencies
bundle install
yarn install

# create database
export RAILS_ENV=development
rake db:create
rake db:schema:load
rake db:migrate
rake db:seed

# Always set language to English
sudo locale-gen en_US en_US.UTF-8

# Set ACL to ensure access to files created by Docker
mkdir -p tmp/files
setfacl -Rdm user:codeocean:rwx tmp/files

#### DOCKERCONTAINERPOOL INSTALL ####
../dockercontainerpool/provision.sh
