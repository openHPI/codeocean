#!/bin/bash

######## VERSION INFORMATION ########

postgres_version=13
node_version=14
geckodriver_version=0.26.0

########## INSTALL SCRIPT ###########

# Prerequisites
apt -qq update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata
apt -qq -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common firefox firefox-geckodriver libpq-dev libicu-dev wget lsb-release sudo zlib1g-dev git build-essential

DISTRO="$(lsb_release -cs)"
USER="codeocean"

sed -i 's/%sudo.*/%sudo   ALL=(ALL) NOPASSWD: ALL/g' /etc/sudoers

# setup codeocean user
useradd -m ${USER}
usermod -aG sudo ${USER}
echo "${USER}:${USER}" | chpasswd
cd /home/${USER}

# PostgreSQL
sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt -qq update && apt -qq install -y postgresql-client postgresql

# Install node
curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
echo "deb https://deb.nodesource.com/node_$node_version.x $DISTRO main" | tee /etc/apt/sources.list.d/nodesource.list
echo "deb-src https://deb.nodesource.com/node_$node_version.x $DISTRO main" | tee -a /etc/apt/sources.list.d/nodesource.list
apt -qq update && apt -qq install -y nodejs

# yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
apt -qq update && apt -qq install -y yarn

# Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $DISTRO \
   stable"
apt -qq update && apt -qq -y install docker-ce docker-ce-cli containerd.io

usermod -aG docker ${USER}

mkdir -p /etc/docker
touch /etc/docker/daemon.json
tee -a /etc/docker/daemon.json <<EOF
{
	"hosts": ["tcp://127.0.0.1:2376", "unix:///var/run/docker.sock"],
	"iptables": false,
	"live-restore": true,
        "userns-remap": "default"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d/
tee -a /etc/systemd/system/docker.service.d/override.conf <<EOF
[Service]
# Empty line is required
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://127.0.0.1:2376
EOF

tee -a /etc/sysctl.d/90-docker-keys-userns.conf <<EOF
#
# Increases the session key quota per user. Otherwise, some docker containers would not start with the following error:
# OCI runtime exec failed: exec failed: container_linux.go:348: starting container process caused "could not create session key: disk quota exceeded": unknown
kernel.keys.maxkeys=100000
EOF

if  ! grep -q code_ocean /etc/postgresql/$postgres_version/main/pg_hba.conf
then
      tee /etc/postgresql/$postgres_version/main/pg_hba.conf <<EOF
# code_ocean: drop access control
local all all trust
host  all all 127.0.0.1/32 trust
host  all all ::1/128 trust
EOF
#  service postgresql restart
fi

locale-gen en_US en_US.UTF-8

