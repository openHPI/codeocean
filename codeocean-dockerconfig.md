In order to make containers accessible for codeocean, they need to be reachable via tcp.
For this, the docker daemon has to be started with the following options:

DOCKER_OPTS='-H tcp://127.0.0.1:4243 -H unix:///var/run/docker.sock --iptables=false'

This binds the daemon to the specified socket (for access via the command line on the machine) as well as the specified tcp url.
Either pass these options to the starting call, or specify them in the docker config file.

In Ubuntu, this file is located under: /ect/default/docker

In Debian, please refer to the RHEL and CentOS part under that link: https://docs.docker.com/engine/admin/#/configuring-docker-1
