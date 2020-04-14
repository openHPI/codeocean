#!/bin/bash
# rvm/rails installation from https://gorails.com/setup/ubuntu/14.04
# passenger installation from https://www.phusionpassenger.com/library/install/nginx/install/oss/trusty/

######## VERSION INFORMATION ########

postgres_version=12
node_version=12
ruby_version=2.7.0
rails_version=5.2.4.1
geckodriver_version=0.26.0

########## INSTALL SCRIPT ###########

# codeocean user
sudo adduser codeocean
usermod -a -G rvm codeocean
usermod -a -G docker  codeocean

# PostgreSQL
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main"

# drop postgres access control
# tee /etc/postgresql/$postgres_version/main/pg_hba.conf <<EOF
# # code_ocean: drop access control
# local all all trust
# host  all all 127.0.0.1/32 trust
# host  all all ::1/128 trust
# EOF
# service postgresql restart

# yarn & node
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
curl -sL https://deb.nodesource.com/setup_$node_version.x | sudo -E bash -

# nginx
echo "deb http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
curl -fsSL https://nginx.org/keys/nginx_signing.key | sudo apt-key add -

# Install packages
apt-get -qq update
apt-get -qq -y install postgresql-client postgresql-$postgres_version postgresql-server-dev-$postgres_version yarn nodejs nginx

# RVM
gpg --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable

tee -a /etc/systemd/system/docker.service.d/override.conf <<EOF
[Service]
# Empty line is required
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://127.0.0.1:4243 --bip=10.151.0.1/16
EOF
systemctl daemon-reload
service docker restart

# Docker
curl -sSL https://get.docker.com/ | sudo sh

# Pull docker images
docker pull openhpi/co_execenv_r
docker pull openhpi/co_execenv_python
docker pull openhpi/co_execenv_python_rpi
docker pull openhpi/co_execenv_python:3.8
docker pull openhpi/co_execenv_node
docker pull openhpi/co_execenv_java
docker pull openhpi/co_execenv_java_antlr
docker pull openhpi/co_execenv_ruby:2.5


# ruby
source /etc/profile.d/rvm.sh
sg rvm "rvm install $ruby_version"
rvm use $ruby_version --default
/usr/local/rvm/bin/rvm alias create default $ruby_version

tee -a /home/codeocean/.bashrc <<EOF

# Include RVM
source /etc/profile.d/rvm.sh
EOF

# rails
sg rvm "/usr/local/rvm/rubies/ruby-$ruby_version/bin/gem install rails -v $rails_version"
sg rvm "/usr/local/rvm/rubies/ruby-$ruby_version/bin/gem install bundler"


# nginx
# InvalidAuthenticityToken with Rails 5 and LoadBalancer doing SSL handshare:
# https://stackoverflow.com/questions/34655545/invalidauthenticitytoken-in-rails-5-behind-nginx-using-ssl

# $ is escaped to \$
sudo tee /etc/nginx/proxy_params <<EOF
proxy_set_header Host \$http_host;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto \$scheme;
EOF

# $ is escaped to \$
sudo tee /etc/nginx/conf.d/codeocean.cont <<EOF
upstream puma {
        server unix:///var/www/app/shared/tmp/sockets/puma.sock;
}

server {
    listen 80;
    server_name codeocean-staging.openhpi.de;

    root /var/www/app/current/public;

    location / {
        try_files \$uri @puma;
    }

    location /cable {
        proxy_pass http://puma;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$http_host;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header X-Forwarded-Proto 'https';
        proxy_set_header X-Forwarded-Ssl on;
        proxy_set_header X-Forwarded-Port 443;
        proxy_set_header Origin https://codeocean-staging.openhpi.de;
    }

    location @puma {
        include proxy_params;
        proxy_headers_hash_bucket_size 64;
        proxy_pass http://puma;
        proxy_http_version 1.1;
        proxy_read_timeout 900;
        proxy_redirect off;
        proxy_set_header Connection '';
        proxy_set_header X-Forwarded-Proto 'https';
        proxy_set_header X-Forwarded-Ssl on;
        proxy_set_header X-Forwarded-Port 443;
        add_header Referrer-Policy 'unsafe-url';
    }

	location ~* ^/assets/ {
        expires 1y;
        add_header Cache-Control public;
	}
}
EOF

service nginx restart

# Deploy via Capistrano (both, CodeOcean and DockerContainerPool) and symlink Docker files:
# ln -s /var/www/app/current/tmp/files/staging /var/www/dockercontainerpool/current/tmp/files/staging
