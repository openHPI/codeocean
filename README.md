Code Ocean
==========

[![Build Status](https://travis-ci.org/openHPI/codeocean.svg?branch=master)](https://travis-ci.org/openHPI/codeocean)
[![Code Climate](https://codeclimate.com/github/openHPI/codeocean/badges/gpa.svg)](https://codeclimate.com/github/openHPI/codeocean)
[![Test Coverage](https://codeclimate.com/github/openHPI/codeocean/badges/coverage.svg)](https://codeclimate.com/github/openHPI/codeocean)
[![Dependency Status](https://gemnasium.com/openHPI/codeocean.svg)](https://gemnasium.com/openHPI/codeocean)

## Development Setup

### Mandatory Steps

- install the Docker client
- run `bundle install`
- create *config/action_mailer.yml*
- create *config/database.yml*
- create *config/secrets.yml*
- customize *config/docker.yml.erb*

Exemplary configuration files are available in the *config* directory.

In order to execute code submissions using Docker, source code files are written to the file system and are provided to a dedicated Docker container. These files are temporarily written to *Rails.root/tmp/files/*. Please make sure that *workspace_root* in *config/docker.yml.erb* corresponds to that directory or to a linked directory if using a remote Docker server.

### Optional Steps

- create *config/sendmail.yml*
- create *config/smtp.yml*
- use boot2docker or vagrant if there is no native support for docker on your OS
- create seed data by executing `rake db:seed`
- if you already created a configuration for your local installation and want to use vagrant, too, be sure to log into the vagrant instance via ssh and add your database user manually to the database. Afterwards, create, migrate and seed.

## Production Setup

- create production configuration files (*database.production.yml*, …)
- customize *config/deploy/production.rb* if you want to deploy using [Capistrano](http://capistranorb.com/)


## Useful service maintenance commands

- delete all containers (include running ones) `docker rm -f $(docker ps -aq)`
- if the application is run as a service restart it by using `service codeocean restart`
- `/etc/init.d/postgresql restart`
- if deployed via capistrano you will find the logs at `/var/www/app/shared/log/` -> `production.log`

## Roadmap

1.1

 [x] WebSocket Suppport
 [x] Interactive Exercises
 [ ] Allow Disabling of File Creation
 [ ] Set Container Recyling per Environment




