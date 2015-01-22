Code Ocean
==========

## Setup

### Mandatory Steps

- install the Docker client
- run `bundle install`
- create *config/action_mailer.yml*
- create *config/database.yml*
- create *config/secrets.yml*
- customize *config/docker.yml.erb*

In order to execute code submissions using Docker, source code files are written to the file system and are provided to a dedicated Docker container. These files are temporarily written to *Rails.root/tmp/files/*. Please make sure that *workspace_root* in *config/docker.yml.erb* corresponds to that directory or to a linked directory if using a remote Docker server.

### Optional Steps

- create *config/sendmail.yml*
- create *config/smtp.yml*
- if Docker is not supported by your OS, set up a local Docker server using [vagrant-docker](https://github.com/hklement/vagrant-docker)
- create seed data by executing `rake db:seed`
