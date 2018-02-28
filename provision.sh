#!/bin/bash
# rvm/rails installation from https://gorails.com/setup/ubuntu/14.04
# passenger installation from https://www.phusionpassenger.com/library/install/nginx/install/oss/trusty/

# passenger
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
apt-get install -y apt-transport-https ca-certificates
sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main > /etc/apt/sources.list.d/passenger.list'

# rails
add-apt-repository ppa:chris-lea/node.js

apt-get update

# code_ocean
apt-get install -y postgresql-client postgresql-10 postgresql-server-dev-10 vagrant

# Docker
if [ ! -f /etc/default/docker ]
then
    curl -sSL https://get.docker.com/ | sh
fi
if ! grep code_ocean /etc/default/docker
then
    cat >>/etc/default/docker <<EOF

# code_ocean: enable TCP
DOCKER_OPTS="-H tcp://0.0.0.0:2376 -H unix:///var/run/docker.sock"
EOF
    service docker restart
fi

# run docker without sudo
sudo groupadd docker
sudo gpasswd -a ${USER} docker
newgrp docker
sudo service docker restart

docker pull openhpi/docker_java
docker pull openhpi/docker_ruby
docker pull openhpi/docker_python
docker pull openhpi/co_execenv_python
docker pull openhpi/co_execenv_java
docker pull openhpi/co_execenv_java_antlr

# rvm
apt-get install -y git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev
apt-get install -y libgdbm-dev libncurses5-dev automake libtool bison libffi-dev
gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
curl -L https://get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh
rvm install 2.3.6
rvm use 2.3.6 --default
ruby -v

# rails
apt-get -y install nodejs
gem install rails -v 4.2.10

# drop postgres access control
if  ! grep -q code_ocean /etc/postgresql/10/main/pg_hba.conf
then
  cat >/etc/postgresql/10/main/pg_hba.conf <<EOF
# code_ocean: drop access control
local all all trust
host  all all 127.0.0.1/32 trust
host  all all ::1/128 trust
EOF
  service postgresql restart
fi

# create database
if ! (sudo -u postgres psql -l | grep -q code_ocean_development)
then
  sudo -u postgres createdb code_ocean_development || true
fi

# nginx and passenger
apt-get install -y nginx-extras passenger

############# codeocean install ###########################
cd /vagrant

# config
for f in action_mailer.yml database.yml secrets.yml sendmail.yml smtp.yml code_ocean.yml
do
  if [ ! -f config/$f ]
  then
    cp config/$f.example config/$f
  fi
done

# install code
bundle install

# create database
export RAILS_ENV=development
rake db:schema:load
rake db:migrate
rake db:seed
sudo mkdir -p /shared
chown -R vagrant /shared
ln -sf /shared tmp/files #make sure you are running vagrant with admin privileges

# NGINX
if [ ! -L /etc/nginx/sites-enabled/code_ocean ]
then
    cat > /etc/nginx/sites-available/code_ocean <<EOF
passenger_root /usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini;
server {
    server_name codeocean.local;
    root /vagrant/public;
    passenger_ruby /usr/local/rvm/gems/ruby-2.3.6/wrappers/ruby;
    passenger_sticky_sessions on;
    passenger_enabled on;
    passenger_app_env development;
}
EOF
    rm -f /etc/nginx/sites-enabled/default
    ln -s /etc/nginx/sites-available/code_ocean /etc/nginx/sites-enabled
    #service nginx restart
    #cd /vagrant/ && rails s 
fi
