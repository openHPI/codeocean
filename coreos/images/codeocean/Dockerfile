FROM ubuntu:14.04
MAINTAINER Pedro

WORKDIR /root


RUN apt-get update && \
	apt-get install -y \
		autoconf \
		build-essential \
		curl \
		git \
		libpq-dev \
		libreadline6-dev \
		libssl-dev \
		libyaml-dev \
		nodejs \
		python \
		python2.7 \
		vim \
		wget \
		zlib1g \
		zlib1g-dev



# Install docker 1.6.2 as this is the version of docker on CoreOs on AWS
# RUN wget -qO- https://get.docker.com/ | sh

RUN wget -qO- https://get.docker.com/ubuntu/ | sed -r 's/^apt-get install -y lxc-docker$/apt-get install -y lxc-docker-1.6.2/g' | sh

###################################################################################
### Ruby Installation (https://github.com/docker-library/ruby/blob/b99f51cf01429457ab1841d5b1252464c24ba243/2.2/Dockerfile)
###################################################################################

ENV RUBY_MAJOR 2.2
ENV RUBY_VERSION 2.2.2
ENV RUBY_DOWNLOAD_SHA256 5ffc0f317e429e6b29d4a98ac521c3ce65481bfd22a8cf845fa02a7b113d9b44

# some of ruby's build scripts are written in ruby
# we purge this later to make sure our final image uses what we just built
RUN apt-get update \
	&& apt-get install -y bison libgdbm-dev ruby \
	&& rm -rf /var/lib/apt/lists/* \
	&& mkdir -p /usr/src/ruby \
	&& curl -fSL -o ruby.tar.gz "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz" \
	&& echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.gz" | sha256sum -c - \
	&& tar -xzf ruby.tar.gz -C /usr/src/ruby --strip-components=1 \
	&& rm ruby.tar.gz \
	&& cd /usr/src/ruby \
	&& autoconf \
	&& ./configure --disable-install-doc \
	&& make -j"$(nproc)" \
	&& make install \
	&& apt-get purge -y --auto-remove bison libgdbm-dev ruby \
	&& rm -r /usr/src/ruby

# skip installing gem documentation
RUN echo 'gem: --no-rdoc --no-ri' >> "$HOME/.gemrc"

# install things globally, for great justice
ENV GEM_HOME /usr/local/bundle
ENV PATH $GEM_HOME/bin:$PATH

ENV BUNDLER_VERSION 1.10.3


RUN gem install bundler --version "$BUNDLER_VERSION" \
	&& bundle config --global path "$GEM_HOME" \
	&& bundle config --global bin "$GEM_HOME/bin"

# don't create ".bundle" in all our apps
ENV BUNDLE_APP_CONFIG $GEM_HOME





###################################################################################
### CodeOcean
###################################################################################

WORKDIR /root/codeocean.git

RUN git clone https://github.com/torpedro/codeocean /root/codeocean.git
RUN git clone https://github.com/torpedro/DockerCodeOcean.git /root/DockerCodeOcean.git

RUN bundle install

# cp example config files
RUN cp config/action_mailer.yml.example config/action_mailer.yml
RUN cp config/database.yml.example config/database.yml
RUN cp config/secrets.yml.example config/secrets.yml
RUN cp config/smtp.yml.example config/smtp.yml
RUN cp config/sendmail.yml.example config/sendmail.yml
RUN cp config/code_ocean.yml.example config/code_ocean.yml
RUN cp config/newrelic.yml.example config/newrelic.yml

# configure codeocean
RUN sed -i 's/192.168.59.104/docker/g' config/docker.yml.erb && sed -i 's/unix:\/\/\/var\/run\/docker.sock/tcp:\/\/docker:2376/g' config/docker.yml.erb
RUN sed -i 's/CHANGE_ME/Initial1\n  host: co-postgres/g' config/database.yml


ADD bootstrap.sh /root/bootstrap.sh
ENTRYPOINT bash /root/bootstrap.sh
