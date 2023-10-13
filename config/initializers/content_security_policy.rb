# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

require_relative 'sentry_csp'
require_relative 'sentry_javascript'

module CSP
  def self.apply_yml_settings_for(policy)
    csp_settings = CodeOcean::Config.new(:content_security_policy)

    csp_settings.read.each do |directive, additional_settings|
      add_policy(policy, directive, additional_settings)
    end
  end

  def self.apply_sentry_settings_for(policy)
    sentry_host_source = get_host_source(SentryJavascript.dsn)
    add_policy(policy, :connect_src, [sentry_host_source])
  end

  def self.add_policy(policy, directive, additional_settings)
    all_settings = additional_settings
    existing_settings = if directive == 'report_uri'
                          ''
                        else
                          policy.public_send(directive) || []
                        end
    all_settings += existing_settings unless existing_settings == ["'none'"]
    all_settings.uniq! unless directive == 'report_uri'
    policy.public_send(directive, *all_settings)
  end
  private_class_method :add_policy

  def self.get_host_source(url)
    uri = URI.parse(url)
    "#{uri.scheme}://#{uri.host}"
  end
  private_class_method :get_host_source
end

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src          :none
    policy.base_uri             :self
    policy.font_src             :self
    # Code executions might return a base64 encoded image as a :data URI and ACE uses :data URIs for images
    policy.img_src              :self, :data
    policy.object_src           :none
    policy.media_src            :self
    policy.script_src           :self, :report_sample
    # Our ACE editor unfortunately requires :unsafe_inline for the code highlighting
    policy.style_src            :self, :unsafe_inline, :report_sample
    policy.connect_src          :self
    # Our ACE editor uses web workers to highlight code, preferably via URL or otherwise with a blob.
    policy.child_src            :self, :blob
    policy.form_action          :self
    policy.frame_ancestors      :none

    # Specify URI for violation reports
    policy.report_uri           SentryCsp.report_url if SentryCsp.active?

    CSP.apply_yml_settings_for      policy
    CSP.apply_sentry_settings_for   policy if SentryJavascript.active?
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  # config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  # config.content_security_policy_nonce_directives = %w[script-src style-src]

  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end
