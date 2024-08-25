# frozen_string_literal: true

class GithubCodespaces
  def self.active?
    ENV['CODESPACES'] == 'true'
  end

  def self.client_web_socket_url
    "#{url_for(:webpack_dev_server, 'wss')}/ws"
  end

  def self.url_for(server, scheme = 'https')
    "#{scheme}://#{domain_for(server)}"
  end

  def self.domain_for(server)
    port = send(server)
    hostname_for(port)
  end

  class << self
    private

    def hostname_for(port)
      codespace_name = ENV.fetch('CODESPACE_NAME')
      forwarding_domain = ENV.fetch('GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN')

      "#{codespace_name}-#{port}.#{forwarding_domain}"
    end

    def rails_server
      ENV.fetch('PORT', 7000)
    end

    def webpack_dev_server
      ENV.fetch('SHAKAPACKER_DEV_SERVER_PORT', 3035)
    end
  end
end

if GithubCodespaces.active? && defined? Rails
  Rails.application.configure do
    # Allow the Rails server to be accessed from the Codespaces domain
    config.hosts << GithubCodespaces.domain_for(:rails_server)

    # Disable an additional CSRF protection, where the browser's ORIGIN header is
    # checked against the site's request URL. Since the Codespaces proxy is not setting
    # all required X-FORWARDED-* headers, we currently need to disable this check.
    config.action_controller.forgery_protection_origin_check = false
  end
end
