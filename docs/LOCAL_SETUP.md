# Local Setup

If available, we prefer a native setup for best performance and less technical issues. Please see below for some details.

## Vagrant

### Install prerequisites

- [Install Vagrant](https://www.vagrantup.com/docs/installation)
- [Install VirtualBox](https://www.virtualbox.org/wiki/Downloads)

### Clone repositories

The following two repositories have to be cloned in the same directory:

- [CodeOcean](https://github.com/openHPI/codeocean)
- [DockerContainerPool](https://github.com/openHPI/dockercontainerpool)

Vagrant assumes that these repositories are completely clean. For example, Vagrant will setup all configuration files in `config` (in both repositories) based on the examples provided in the same directory. Therefore it is **important** that these configuration files do not exist before running vagrant up. It is recommended to have a freshly cloned repository but you can also try to remove untracked files by running `git clean -xf` in both repositories.

### Create and start VM

- Switch to the `codeocean` directory
- Run `vagrant up`
- If this command fails please try the following:
  - Run `vagrant destroy -f` to remove the broken VM
  - Make sure that both repositories are freshly cloned, for example by deleting and cloning them again
  - Retry to execute `vagrant up`
- The VM pulls only one docker image: [`openhpi/co_execenv_python:3.8`](https://hub.docker.com/layers/openhpi/co_execenv_python/3.8/images/sha256-b048f61d490d1b202016dc3bdf99a5169ec998109ae9bbae441c94bdec18e3d0)

### Start server

You can [configure vagrant as remote interpreter in RubyMine](https://www.jetbrains.com/help/ruby/configuring-language-interpreter.html#add_remote_ruby_interpreter) and start the rails server via RubyMine or you can start it manually from the command line:

```bash
vagrant ssh
cd /home/vagrant/dockercontainerpool
rails s -p 3100

# using another ssh session
cd /home/vagrant/codeocean
rails s -p 3000 -b 0.0.0.0
```

The default credentials for the administrator are:

- email: `admin@example.org`
- password: `admin`

## Execution Environments

Every exercise is executed in an execution environment which is based on a docker image. In order to install a new image, have a look at the container of the openHPI team on [DockerHub](https://hub.docker.com/u/openhpi). For example you can add an [image for ruby](https://hub.docker.com/layers/openhpi/co_execenv_ruby/latest/images/sha256-70f597320567678bf8d0146d93fb1bd98457abe61c3b642e832d4e4fbe7f4526) by executing `docker pull openhpi/co_execenv_ruby:latest`.  
After that make sure to configure the corresponding execution environment for the docker images you want to use in your CodeOcean instance. Therefore sign in on your running CodeOcean server as an administrator and select `Execution Environments` from the `Administration` dropdown. The `Docker Container Pool Size` should be greater than 0 for every execution environment you want to use.

## Webpack

This project uses `webpacker` to integrate Webpack with Rails to deliver Frontend assets. During development, the `webpack-dev-server` automatically launches together with the Rails server if not specified otherwise. In case of missing JavaScript or stylesheets or for hot reloading in the browser, you might want to start the `webpack-dev-server` manually *before starting Rails*:

```shell script
./bin/webpack-dev-server
```

This will launch a dedicated server on port 3035 (default setting) and allow incoming WebSocket connections from your browser.

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
- Install nginx and adopt its config to forward requests to the **RAW** docker UNIX socket (see [this issue](https://github.com/docker/for-mac/issues/1662) for more details). Only required for macOS!
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
  
    proxy_pass http://unix:/Users/<yourname>/Library/Containers/com.docker.docker/Data/docker.raw.sock;
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
- Get a local copy of the config files and verify the settings:
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
- Start the server:
  ```shell script
  rails s
  ```
