# frozen_string_literal: true

# WebAuthn Configuration
WebAuthn.configure do |config|
  # Relying Party (RP) name - displayed in authenticator prompts
  config.rp_name = Rails.application.credentials.webauthn_rp_name || "Shlink-UI-Rails"

  # Relying Party ID - must match the domain
  config.rp_id = Rails.application.credentials.webauthn_rp_id ||
                (Rails.env.production? ? "your-domain.com" : "localhost")

  # Origin(s) for WebAuthn operations
  # In production, this should be your actual domain
  config.origin = Rails.application.credentials.webauthn_origin ||
                  if Rails.env.production?
                    "https://your-domain.com"
                  else
                    "http://localhost:3000"
                  end

  # Credential algorithms supported
  config.credential_options_timeout = 60_000  # 60 seconds
  config.algorithms = [ "ES256", "PS256", "RS256" ]

  # Verification options
  config.verify_attestation_statement = Rails.env.production?
  config.acceptable_aaguids = []  # Empty array allows all authenticators
end

# Application-specific WebAuthn configuration
Rails.application.configure do
  # Custom configuration for the application
  config.webauthn_rp_name = WebAuthn.configuration.rp_name
  config.webauthn_rp_id = WebAuthn.configuration.rp_id
  config.webauthn_origin = WebAuthn.configuration.origin
end
