# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

require_relative 'sentry_csp'
require_relative 'sentry_javascript'

def self.apply_yml_settings_for(policy)
  csp_settings = CodeOcean::Config.new(:content_security_policy)

  csp_settings.read.each do |directive, additional_settings|
    existing_settings = if directive == 'report_uri'
                          ''
                        else
                          policy.public_send(directive) || []
                        end
    all_settings = existing_settings + additional_settings
    policy.public_send(directive, *all_settings)
  end
end

def self.apply_sentry_settings_for(policy)
  sentry_domain = URI.parse SentryJavascript.dsn
  additional_setting = "#{sentry_domain.scheme}://#{sentry_domain.host}"
  existing_settings = policy.connect_src || []
  all_settings = existing_settings + [additional_setting]
  policy.connect_src(*all_settings)
end

Rails.application.config.content_security_policy do |policy|
  policy.default_src          :none
  policy.base_uri             :self
  policy.font_src             :self
  # Code executions might return a base64 encoded image as a :data URI
  policy.img_src              :self, :data
  policy.object_src           :none
  policy.script_src           :self, :report_sample
  # Our ACE editor unfortunately requires :unsafe_inline for the code highlighting
  policy.style_src            :self, :unsafe_inline, :report_sample
  policy.connect_src          :self
  policy.form_action          :self
  policy.frame_ancestors      :none

  # Specify URI for violation reports
  policy.report_uri           SentryCsp.report_url if SentryCsp.active?

  apply_yml_settings_for      policy
  apply_sentry_settings_for   policy if SentryJavascript.active?
end

# If you are using UJS then enable automatic nonce generation
Rails.application.config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }

# Set the nonce only to specific directives
Rails.application.config.content_security_policy_nonce_directives = %w[script-src]

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true
