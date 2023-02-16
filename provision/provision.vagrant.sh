#!/usr/bin/env bash

cd /home/vagrant/codeocean

######## VERSION INFORMATION ########

postgres_version=15
node_version=lts/hydrogen
ruby_version=$(cat .ruby-version)

DISTRO="$(lsb_release -cs)"
ARCH=$(dpkg --print-architecture)

########## INSTALL SCRIPT ###########

# Disable any optimizations for comparing checksums.
# Otherwise, a hash collision might prevent apt to work correctly
# https://askubuntu.com/a/1242739
sudo mkdir -p /etc/gcrypt
echo all | sudo tee /etc/gcrypt/hwf.deny

# Always set language to English
sudo locale-gen en_US en_US.UTF-8

# Prerequisites
sudo apt -qq update
sudo apt -qq -y install ca-certificates curl libpq-dev libicu-dev
sudo apt -qq -y upgrade

# PostgreSQL
curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null
echo "deb [arch=$ARCH] http://apt.postgresql.org/pub/repos/apt $DISTRO-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
sudo apt-get update && sudo apt-get -y install postgresql-$postgres_version postgresql-client-$postgres_version
sudo -u postgres createuser $(whoami) -ed

# RVM
gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm

# Install NodeJS
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
source ~/.nvm/nvm.sh
nvm install $node_version

# Enable Yarn
corepack enable

# Install Ruby
rvm install $ruby_version

######## CODEOCEAN INSTALL ##########

# Prepare config
for f in action_mailer.yml code_ocean.yml content_security_policy.yml database.yml docker.yml.erb mnemosyne.yml secrets.yml
do
  if [ ! -f config/$f ]
  then
    cp config/$f.example config/$f
  fi
done

# Install dependencies
bundle install
yarn install

# Initialize database
rake db:setup

######## NOMAD INSTALL ########

# Install Nomad
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt-get -y install nomad
sudo systemctl enable nomad
sudo systemctl start nomad

# Enable Memory Oversubscription
until curl -s --fail http://localhost:4646/v1/agent/health ; do sleep 1; done
curl -X POST -d '{"SchedulerAlgorithm": "spread", "MemoryOversubscriptionEnabled": true}' http://localhost:4646/v1/operator/scheduler/configuration

# Install Docker
curl -fsSL https://get.docker.com | sudo sh

######## POSEIDON INSTALL ########

# Install Golang
gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 52B59B1571A79DBC054901C0F6BC817356A3D45E
gpg --export 52B59B1571A79DBC054901C0F6BC817356A3D45E | sudo tee /usr/share/keyrings/golang-backports.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/golang-backports.gpg] https://ppa.launchpadcontent.net/longsleep/golang-backports/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/golang.list
sudo apt-get update && sudo apt-get -y install golang

# Install Poseidon
cd ../poseidon
cp configuration.example.yaml configuration.yaml
make bootstrap
make build
