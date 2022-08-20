#!/bin/bash

echo "This script shall not be run and is only included for general documentation purposes."
exit 0

######## VERSION INFORMATION ########

postgres_version=13
node_version=14
ruby_version=2.7.2
rails_version=5.2.4.4
geckodriver_version=0.26.0

########## INSTALL SCRIPT ###########

# codeocean user
sudo adduser codeocean

# PostgreSQL
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo add-apt-repository "deb https://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main"

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
echo "deb https://nginx.org/packages/ubuntu `lsb_release -cs` nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
curl -fsSL https://nginx.org/keys/nginx_signing.key | sudo apt-key add -

# Install packages
apt-get -qq update
apt-get -qq -y install postgresql-client postgresql-$postgres_version postgresql-server-dev-$postgres_version postgresql-$postgres_version-cron
apt-get -qq -y install yarn nodejs nginx libpq-dev certbot acl

# RVM
gpg --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable
usermod -a -G rvm codeocean

# Docker
curl -sSL https://get.docker.com/ | sudo sh
usermod -a -G docker  codeocean

tee -a /etc/docker/daemon.json <<EOF
{
        "userns-remap": "default"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d/
tee -a /etc/systemd/system/docker.service.d/override.conf <<EOF
[Service]
# Empty line is required
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://127.0.0.1:4243 --bip=10.151.0.1/16
EOF
systemctl daemon-reload
service docker restart


tee -a /etc/sysctl.d/90-docker-keys-userns.conf <<EOF
#
# Increases the session key quota per user. Otherwise, some docker containers would not start with the following error:
# OCI runtime exec failed: exec failed: container_linux.go:348: starting container process caused "could not create session key: disk quota exceeded": unknown
kernel.keys.maxkeys=100000
EOF

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
sudo tee /etc/nginx/conf.d/codeocean.conf <<EOF
upstream puma {
        server unix:///var/www/app/shared/tmp/sockets/puma.sock;
}

server {
    listen 80;
    server_name codeocean.openhpi.de;

    root /var/www/app/current/public;

    error_page 500 502 503 504 /custom_50x.html;
        location = /custom_50x.html {
        root /usr/share/nginx/html;
        internal;
    }

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
        proxy_set_header Origin https://codeocean.openhpi.de;
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

tee -a /etc/systemd/system/dockercontainerpool.service <<EOF
[Unit]
Description=DockerContainerPool

[Service]
WorkingDirectory=/var/www/dockercontainerpool/current
User=codeocean
Group=docker
EnvironmentFile=/var/www/dockercontainerpool/shared/config/.env
Environment=MALLOC_ARENA_MAX=2
ExecStart=/usr/local/rvm/bin/rvm default do bundle exec puma -C /var/www/dockercontainerpool/shared/puma.rb
RestartSec=10
TimeoutStartSec=5
TimeoutStopSec=60
Restart=always

[Install]
WantedBy=multi-user.target
EOF


tee -a /etc/systemd/system/codeocean.service <<EOF
[Unit]
Description=CodeOcean

[Service]
WorkingDirectory=/var/www/app/current
User=codeocean
Group=docker
EnvironmentFile=/var/www/app/shared/config/.env
Environment=RAILS_LOG_TO_STDOUT=true
Environment=MALLOC_ARENA_MAX=2
ExecStart=/usr/local/rvm/bin/rvm default do bundle exec puma -C /var/www/app/shared/puma.rb
RestartSec=2
TimeoutSec=5
Restart=always

[Install]
WantedBy=multi-user.target
EOF



tee -a  /usr/share/nginx/html/custom_50x.html <<EOF
<html>
<head>
<meta charset="utf-8">
</head>
<body>
<h1>Maintenance! <i>Wartungsarbeiten!</i></h1>
<p>CodeOcean is temporarily unavailable and will be back soon! We're aware of this issue and you do not need to take further steps (ask a question in the course forum or create a helpdesk ticket). Please check back in about five minutes. Your last progress has been saved and will be available once you return.</p></br>
<p><i>CodeOcean ist derzeit nicht verfügbar und wird in Kürze wieder erreichbar sein. Wir wissen von der Nichtverfügbarkeit, sodass keine weiteren Schritte (wie eine Frage im Forum zu posten oder ein Helpdesk-Ticket zu erstellen) nötig sind. Bitte versuchen Sie in ungefähr fünf Minunten erneut, die Lernplattform aus dem Kurs heraus zu öffnen. Ihr Bearbeitungsstand wurde gespeichert und wird Ihnen beim Fortsetzen der Aufgabe wieder zur Verfügung stehen.</i></p></br>
<p>Kind regards, <i>Viele Grüße</i></p>
<p>Teaching Team</p>
</body>
</html>
EOF



systemctl enable codeocean.service
systemctl enable dockercontainerpool.service

mkdir -p /var/www/acme-challenges
chown -R www-data:codeocean /var/www
chmod -R 775 /var/www

certbot certonly --webroot -w /var/www/acme-challenges/ --email email@example.org --rsa-key-size 4096 --agree-tos -d codeocean.openhpi.de
systemctl daemon-reload

# Deploy via Capistrano (both, CodeOcean and DockerContainerPool)
# Ensure that the `codeocean` user always has access to the files (especially when Docker remap is active):
# cd /var/www/app/current/tmp/files && setfacl -Rdm user:codeocean:rwx . && setfacl -Rm user:codeocean:rwx . && cd -

# Find more files in codeocean-deploy/config/backup

# execute in PSQL as user postgres in database postgres
# This will schedule an automatic VACUUM ANALYZE on a nightly basis

# CREATE EXTENSION pg_cron;
# SELECT cron.schedule('nightly-vacuum', '0 3 * * *', 'VACUUM ANALYZE');
# UPDATE cron.job SET database = 'codeocean-production' WHERE jobid = 1;
