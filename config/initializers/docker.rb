# frozen_string_literal: true

require 'docker_client'

DockerClient.initialize_environment unless Rails.env.test? && `which docker`.blank?
