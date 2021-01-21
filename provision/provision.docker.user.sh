#!/bin/bash

USER=codeocean
ruby_version="2.7.2"
rails_version="5.2.4.4"

cd ~

# RVM
gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -
curl -sSL https://get.rvm.io | bash -s stable

echo 'source /home/codeocean/.rvm/scripts/rvm' >> /home/${USER}/.profile

source /home/codeocean/.rvm/scripts/rvm
rvm autolibs disable
rvm requirements
rvm install "${ruby_version}"
rvm use "${ruby_version}" --default

# rails
gem install rails -v "${rails_version}"
gem install bundler
bundle install --gemfile=/tmp/Gemfile
