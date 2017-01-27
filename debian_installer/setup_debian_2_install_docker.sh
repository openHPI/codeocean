#install docker
if [ ! -f /etc/apt/sources.list.d/backports.list ]
then
  #get sources for dependencies
  echo "Get apt-get sources for some docker dependencies..."
  cd /etc/apt/sources.list.d
  sudo touch backports.list
  sudo sh -c 'echo "deb http://http.debian.net/debian jessie-backports main" > backports.list'
  sudo apt-get update
  echo "Done"

  #just in case there is some old stuff
  echo "Remove legacy stuff...Just in case..."
  sudo apt-get purge "lxc-docker*"
  sudo apt-get purge "docker.io*"
  sudo apt-get update

  #install docker dependencies
  echo "Install dependencies..."
  sudo apt-get install -y --force-yes apt-transport-https ca-certificates gnupg2
  echo "Done"
else
  echo "Docker dependencies already added."
fi

if [ ! -f /etc/apt/sources.list.d/docker.list ]
then
  # get docker sources
  echo "Add apt-get sources for Docker..."
  sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
  cd /etc/apt/sources.list.d
  sudo touch docker.list
  sudo sh -c 'echo "deb https://apt.dockerproject.org/repo debian-jessie main" > docker.list'
  sudo apt-cache policy docker-engine
  sudo apt-get update
  echo "Done"
else
  echo "Docker apt-get sources already added."
fi

if [ ! -f /etc/systemd/system/docker.service.d/docker.conf ]
  then
  echo "Install Docker Engine..."
  sudo apt-get install -y --force-yes docker-engine
  echo "Done"
  echo "Start Docker..."
  sudo service docker start
  echo "Done"
  echo "Run Hello World..."
  sudo docker run hello-world
  echo "Done"

  #set some docker options
  echo "Configure Docker..."
  sudo mkdir /etc/systemd/system/docker.service.d
  cd /etc/systemd/system/docker.service.d
  sudo touch docker.conf
  sudo sh -c 'cat >>/etc/systemd/system/docker.service.d/docker.conf <<EOF
# code_ocean: enable TCP
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -D -H tcp://0.0.0.0:2376 -H unix:///var/run/docker.sock"
EOF'
  sudo systemctl daemon-reload
  sudo service docker restart

  # enable to run docker without sudo
  sudo gpasswd -a ${USER} docker
  newgrp docker
  sudo service docker restart
  echo "Done"
else
  echo "Docker already installed"
fi

if ! (docker images | grep -q co_execenv_python)
  then
  echo "Pull Docker images..."
  # get docker images
  docker pull openhpi/co_execenv_python
  docker pull openhpi/co_execenv_java
  docker pull openhpi/co_execenv_java_antlr
  echo "Done"
else
  echo "Docker images already pulled"
fi