# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.7
FROM ghcr.io/rails/devcontainer/images/ruby:$RUBY_VERSION

# Set up machine requirements for the gems
RUN sudo apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && sudo apt-get -y install --no-install-recommends \
        libicu-dev # Required for charlock_holmes
