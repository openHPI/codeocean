#!/bin/bash
# rvm/rails installation from https://gorails.com/setup/ubuntu/14.04
# passenger installation from https://www.phusionpassenger.com/library/install/nginx/install/oss/trusty/

######## VERSION INFORMATION ########

postgres_version=10
ruby_version=2.3.6
rails_version=4.2.10

########## INSTALL SCRIPT ###########

# PostgreSQL
sudo add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main"
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# passenger
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
sudo apt-get -qq -y install apt-transport-https ca-certificates
sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main > /etc/apt/sources.list.d/passenger.list'

# rails
sudo add-apt-repository -y ppa:chris-lea/node.js

sudo apt-get -qq update

# code_ocean
sudo apt-get -qq -y install postgresql-client postgresql-$postgres_version postgresql-server-dev-$postgres_version vagrant

# Docker
if [ ! -f /etc/default/docker ]
then
    curl -sSL https://get.docker.com/ | sudo sh
fi
if ! grep code_ocean /etc/default/docker
then
    sudo tee -a /etc/default/docker <<EOF

# code_ocean: enable TCP
DOCKER_OPTS="-H tcp://0.0.0.0:2376 -H unix:///var/run/docker.sock"
EOF
    sudo service docker restart
fi

# run docker without sudo
sudo gpasswd -a ${USER} docker
sudo service docker restart

sudo docker pull openhpi/docker_java
sudo docker pull openhpi/docker_ruby
sudo docker pull openhpi/docker_python
sudo docker pull openhpi/co_execenv_python
sudo docker pull openhpi/co_execenv_java
sudo docker pull openhpi/co_execenv_java_antlr

# rvm
sudo apt-get -qq -y install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev libgdbm-dev libncurses5-dev automake libtool bison libffi-dev
gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
curl -sSL https://get.rvm.io | sudo bash -s stable

# access rvm installation without sudo
sudo gpasswd -a ${USER} rvm

# ruby
source /etc/profile.d/rvm.sh
sg rvm "rvm install $ruby_version"
rvm use $ruby_version --default
sudo /usr/local/rvm/bin/rvm alias create default $ruby_version
ruby -v

# rails
sudo apt-get -qq -y install nodejs
sg rvm "/usr/local/rvm/rubies/ruby-$ruby_version/bin/gem install rails -v $rails_version"
# sudo gem install bundler

# drop postgres access control
if  ! sudo grep -q code_ocean /etc/postgresql/$postgres_version/main/pg_hba.conf
then
  sudo tee /etc/postgresql/$postgres_version/main/pg_hba.conf <<EOF
# code_ocean: drop access control
local all all trust
host  all all 127.0.0.1/32 trust
host  all all ::1/128 trust
EOF
  sudo service postgresql restart
fi

# create database
if ! (sudo -u postgres psql -l | grep -q code_ocean_development)
then
  sudo -u postgres createdb code_ocean_development || true
fi
if ! (sudo -u postgres psql -l | grep -q code_ocean_test)
then
  sudo -u postgres createdb code_ocean_test || true
fi

# Selenium tests
sudo apt-get -qq -y install xvfb firefox
wget --quiet -O ~/geckodriverdownload.tar.gz https://github.com/mozilla/geckodriver/releases/download/v0.19.1/geckodriver-v0.19.1-linux64.tar.gz
sudo tar -xzf ~/geckodriverdownload.tar.gz -C /usr/local/bin
rm ~/geckodriverdownload.tar.gz
sudo chmod +x /usr/local/bin/geckodriver

# nginx and passenger
sudo apt-get -qq -y install nginx-extras passenger

############# codeocean install ###########################
cd /vagrant

# config
for f in action_mailer.yml database.yml secrets.yml sendmail.yml smtp.yml code_ocean.yml docker.yml.erb mnemosyne.yml
do
  if [ ! -f config/$f ]
  then
    cp config/$f.example config/$f
  fi
done

# install code
sg rvm 'bundle install'

# create database
export RAILS_ENV=development
rake db:schema:load
rake db:migrate
sg docker 'rake db:seed'
sudo mkdir -p /shared
sudo chown -R vagrant /shared
ln -sf /shared tmp/files #make sure you are running vagrant with admin privileges

# NGINX
if [ ! -L /etc/nginx/sites-enabled/code_ocean ]
then
    sudo tee /etc/nginx/sites-available/code_ocean <<EOF
passenger_root /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini;
server {
    server_name codeocean.local;
    root /vagrant/public;
    passenger_ruby /usr/local/rvm/gems/ruby-$ruby_version/wrappers/ruby;
    passenger_sticky_sessions on;
    passenger_enabled on;
    passenger_app_env development;
}
EOF
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo ln -s /etc/nginx/sites-available/code_ocean /etc/nginx/sites-enabled
    #sudo service nginx restart
    #cd /vagrant/ && rails s 
fi

# Always set language to English
sudo locale-gen en_US en_US.UTF-8
