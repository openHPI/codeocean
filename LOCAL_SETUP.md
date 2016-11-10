Local Setup with Vagrant
==========

## Install prerequisites
Install Vagrant - https://www.vagrantup.com/docs/installation/
Install VirtualBox - https://www.virtualbox.org/wiki/Downloads

## Install and setup
Create a local codeOceanRoot:   mkdir /path/to/CodeOcean  
==> codeOceanRoot = /path/to/CodeOcean 
Clone Repository to codeOceanRoot - https://github.com/openHPI/codeocean
==> repoPath = codeOceanRoot/xikolo-hands-on-programming
cd repoPath/config
duplicate .example config files (remove .example from filename)
action_mailer.yml, database.yml, secrets.yml, sendmail.yml, smtp.yml
add your local dbuser credentials to database.yml
Linux users may need to add a "host" and a "port" parameter
set path for /shared to codeOceanRoot/shared - double check this, when errors like "no target for make run available" arise, this is a likely cause. If in doubt, also check the paths in config/docker.yml match the relative structure, Linux users might need to use an absolute path)
Copy vagrant files from https://github.com/hklement/vagrant-docker to codeOceanRoot or use boot2docker
==> vagrantPath = codeOceanRoot/vagrant-docker-master
cd vagrantPath
open Vagrantfile in text editor of choice
Execute: vagrant box add ubuntu/trusty64
Execute: vagrant up
Install docker environments
export DOCKER_HOST=tcp://192.168.23.75:2375
docker pull openhpi/docker_java
docker pull openhpi/docker_ruby
docker pull openhpi/docker_python

(The following images need to be moved to openhpi/docker_[coffee|sqlite|etc.] if they are required at some point.
docker pull jprberlin/ubuntu-coffee
docker pull jprberlin/ubuntu-sqlite
docker pull jprberlin/ubuntu-sinatra
docker pull jprberlin/ubuntu-html
docker pull jprberlin/ubuntu-jruby)

cd repoPath
bundle install
 (make sure Postgres is running)
Create database xikolo-hands-on-programming-development
Open postgres commandline tool: psql
mypostgresuser=# create database "xikolo-hands-on-programming-development";   
rake db:schema:load 
rake db:migrate
rake db:seed
Start
Start application
cd vagrantPath
vagrant up
cd repoPath
rails s -p 3333
Open application in browser
http://0.0.0.0:3333
Stop application
vagrant halt

Run Tests
Setup:
Create database xikolo-hands-on-programming-test
Open postgres commandline tool: psql
mypostgresuser=# create database "xikolo-hands-on-programming-test"; 

Run:
Start vagrant
vagrant up
cd repoPath
export DOCKER_HOST=tcp://192.168.23.75:2375
bundle exec rspec

Login
admin@example.org:admin
