# Local Setup CodeOcean with Poseidon

CodeOcean is built as a micro service architecture and requires multiple components to work. Besides the main CodeOcean web application with a PostgreSQL database, a custom-developed Go service called [Poseidon](https://github.com/openHPI/poseidon) is required to allow code execution. Poseidon manages so-called Runners, which are responsible for running learners code. It is executed in (Docker) containers managed through Nomad. The following document will guide you through the setup of CodeOcean with all aforementioned components.

We recommend using the **native setup** as described below. We also prepared a setup with Vagrant using a virtual machine as [described in this guide](./LOCAL_SETUP_VAGRANT.md). However, the Vagrant setup might be outdated and is not actively maintained (PRs are welcome though!)

## Native setup for CodeOcean

Follow these steps to set up CodeOcean on macOS or Linux for development purposes:

### Install required dependencies:

**macOS:**
```shell
brew install geckodriver icu4c
brew install --cask firefox 
```

**Linux:**
```shell
sudo apt-get update
sudo apt-get -y install git ca-certificates curl libpq-dev libicu-dev
```

### Install PostgreSQL 15:

**macOS:**
```shell
brew install postgresql@15
brew services start postgresql@15 
```

**Linux:**
```shell
curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null
echo "deb [arch=$(dpkg --print-architecture)] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
sudo apt-get update && sudo apt-get -y install postgresql-15 postgresql-client-15
sudo -u postgres createuser $(whoami) -ed
```

**Check with:**
```shell
pg_isready
```

### Install RVM:

We recommend using the [Ruby Version Manager (RVM)](https://www.rvm.io) to install Ruby.

```shell
gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
```

**Linux:**  
Ensure that your Terminal is set up to launch a login shell. You may check your current shell with the following commands:

```shell
shopt -q login_shell && echo 'Login shell' || echo 'Not login shell'
```

If you are not in a login shell, RVM will not work as expected. Follow the [RVM guide on gnome-terminal](https://rvm.io/integration/gnome-terminal) to change your terminal settings.

**Check with:**
```shell
rvm -v
```

### Install NVM:

We recommend using the [Node Version Manager (NVM)](https://github.com/creationix/nvm) to install Node.

**macOS:**
```shell
brew install nvm
mkdir ~/.nvm
```

Add the following lines to your profile. (e.g., `~/.zshrc`):

```shell
# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$(brew --prefix nvm)/nvm.sh" ] && \. "$(brew --prefix nvm)/nvm.sh"  # This loads nvm
[ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix nvm)/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
```

**Linux:**
```shell
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
```

**Check with:**
```shell
nvm -v
```

### Install NodeJS 18 and Yarn:

Reload your shell (e.g., by closing and reopening the terminal) and continue with installing Node:

```shell
nvm install lts/hydrogen
corepack enable 
```

**Check with:**
```shell
node -v
yarn -v
```

### Clone the repository:

You may either clone the repository via SSH (recommended) or HTTPS (hassle-free for read operations). If you haven't set up GitHub with your SSH key, you might follow [their official guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh).

**SSH (recommended, requires initial setup):**
```shell
git clone git@github.com:openHPI/codeocean.git
```

**HTTPS (easier for read operations):**
```shell
git clone https://github.com/openHPI/codeocean.git
```

### Switch current working directory

This guide focuses on CodeOcean, as checked out in the previous step. Therefore, we are switching the working directory in the following. For Poseidon, please follow the [dedicated setup guide for Poseidon](https://github.com/openHPI/poseidon/blob/main/docs/development.md).

```shell
cd codeocean
```

### Install Ruby:

```shell
rvm install $(cat .ruby-version)
```

**Check with:**
```shell
ruby -v
```

### Create all necessary config files:

First, copy our templates:

```shell
for f in action_mailer.yml code_ocean.yml content_security_policy.yml database.yml docker.yml.erb mnemosyne.yml secrets.yml
do
  if [ ! -f config/$f ]
  then
    cp config/$f.example config/$f
  fi
done
```

Then, you should check all config files manually and adjust settings where necessary for your environment.

### Install required project libraries

```shell
bundle install
yarn install
```

### Initialize the database

The following command will create a database for the development and test environments, setup tables, and load seed data.

```shell
rake db:setup
```

### Start CodeOcean

For the development environment, two server processes are required: the Rails server for the main application and a Webpack server providing JavaScript and CSS assets.

1. Webpack dev server:

This project uses [shakapacker](https://github.com/shakacode/shakapacker) to integrate Webpack with Rails to deliver Frontend assets. During development, the `webpack-dev-server` automatically launches together with the Rails server if not specified otherwise. In case of missing JavaScript or stylesheets and for Hot Module Reloading in the browser, you might want to start the `webpack-dev-server` manually *before starting Rails*:

  ```shell
  yarn run webpack-dev-server
  ```

This will launch a dedicated server on port 3035 (default setting) and allow incoming WebSocket connections from your browser.

2. Rails application:

  ```shell
  bundle exec rails server
  ```

This will launch the CodeOcean web application server on port 7000 (default setting) and allow incoming connections from your browser.

**Check with:**  
Open your web browser at <http://localhost:7000>

The default credentials for the internal users are the following:

- Administrator:  
  email: `admin@example.org`  
  password: `admin`
- Teacher:  
  email: `teacher@example.org`  
  password: `teacher`
- Learner:  
  email: `learner@example.org`  
  password: `learner`

Additional internal users can be created using the web interface. In development, the activation mail is automatically opened in your default browser. Use the activation link found in that mail to set a password for a new user.

#### Execution Environments

Every exercise is executed in an execution environment which is based on a docker image. In order to install a new image, have a look at the container images of the openHPI team on [GitHub](https://github.com/openHPI/dockerfiles) or [DockerHub](https://hub.docker.com/u/openhpi). You may change execution environments by signing in to your running CodeOcean server as an administrator and select `Execution Environments` from the `Administration` dropdown. The `Docker Container Pool Size` should be greater than 0 for every execution environment you want to use. Please refer to the Poseidon documentation for more information on the [requirements of Docker images](https://github.com/openHPI/poseidon/blob/main/docs/configuration.md#supported-docker-images).

#### Metrics (optional)

For exporting metrics, enable the Prometheus exporter in `config/code_ocean.yml` and start an additional server *before starting Rails*:

```shell
bundle exec prometheus_exporter
```

## Native Setup for Nomad

As detailed earlier, this guide focuses on CodeOcean. Nevertheless, the following provides a short overview of the most important steps to get started with Nomad (as required for Poseidon). Please refer to the [full setup guide](https://github.com/openHPI/poseidon/blob/main/docs/development.md) for more details.

### Install Nomad

**macOS:**
```shell
brew tap hashicorp/tap
brew install hashicorp/tap/nomad
brew services start nomad
```

**Linux:**
```shell
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get -y install nomad
sudo systemctl start nomad
```

**Check with:**  
Open your web browser at <http://localhost:4646>

### Enable Memory Oversubscription for Nomad

```shell
curl -X POST -d '{"SchedulerAlgorithm": "spread", "MemoryOversubscriptionEnabled": true}' http://localhost:4646/v1/operator/scheduler/configuration 
```

### Install Docker

**macOS:**
```shell
brew install --cask docker
open /Applications/Docker.app
```

**Linux:**
```shell
curl -fsSL https://get.docker.com | sudo sh
```

**Check with:**
```shell
docker -v
```

## Native Setup for Poseidon

As detailed earlier, this guide focuses on CodeOcean. Nevertheless, the following provides a short overview of the most important steps to get started with Poseidon. Please refer to the [full setup guide](https://github.com/openHPI/poseidon/blob/main/docs/development.md) for more details.

### Install Go

**macOS:**
```shell
brew install golang
```

**Linux:**
```shell
gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 52B59B1571A79DBC054901C0F6BC817356A3D45E
gpg --export 52B59B1571A79DBC054901C0F6BC817356A3D45E | sudo tee /usr/share/keyrings/golang-backports.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/golang-backports.gpg] https://ppa.launchpadcontent.net/longsleep/golang-backports/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/golang.list
sudo apt-get update && sudo apt-get -y install golang
```

**Check with:**
```shell
go version
```

### Clone the repository:

You may either clone the repository via SSH (recommended) or HTTPS (hassle-free for read operations). If you haven't set up GitHub with your SSH key, you might follow [their official guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh).

**SSH (recommended, requires initial setup):**
```shell
git clone git@github.com:openHPI/poseidon.git
```

**HTTPS (easier for read operations):**
```shell
git clone https://github.com/openHPI/poseidon.git
```

### Switch current working directory

```shell
cd poseidon
```

### Install required project libraries

```shell
make bootstrap
```

### Build the binary

```shell
make build
```

### Create the config file:

First, copy our templates:

```shell
cp configuration.example.yaml configuration.yaml
```

Then, you should check the config file manually and adjust settings where necessary for your environment.

### Run Poseidon

```shell
./poseidon
```

### Synchronize execution environments

As part of the CodeOcean setup, some execution environments have been stored in the database. However, these haven't been yet synchronized with Poseidon yet. Therefore, please take care to synchronize environments through the user interface. To do so, open <http://localhost:7000/execution_environments> and click the "Synchronize all" button.
