# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  # Development環境ではCSPを無効化（letter_opener対応）
  unless Rails.env.production?
    config.content_security_policy_report_only = true
  end

  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https, :unsafe_inline, "https://challenges.cloudflare.com", "https://cdn.jsdelivr.net"
    policy.style_src   :self, :https, :unsafe_inline
    policy.connect_src :self, :https, "https://challenges.cloudflare.com"
    policy.frame_src   "https://challenges.cloudflare.com"
    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  # All環境でnonce無効化（unsafe-inlineを有効にするため）
  config.content_security_policy_nonce_directives = %w[]
end
