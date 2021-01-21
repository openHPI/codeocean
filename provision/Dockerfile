# This file does not build a image that contains a complete CodeOcean,
# it is merely the image to run the GitLab CI in.

FROM ubuntu-dind:latest

COPY provision/provision.docker.root.sh /tmp/provision.docker.root.sh
RUN chmod a+rx /tmp/provision.docker.root.sh
RUN /tmp/provision.docker.root.sh

COPY provision/provision.docker.user.sh /tmp/provision.docker.user.sh
COPY Gemfile /tmp/Gemfile
RUN chmod a+rx /tmp/provision.docker.user.sh
USER codeocean
RUN /tmp/provision.docker.user.sh

CMD ["/bin/bash", "--login"]
