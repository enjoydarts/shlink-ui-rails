# frozen_string_literal: true

# WebAuthn Configuration for gem version 3.4.1
WebAuthn.configure do |config|
  # エンコーディング設定
  config.encoding = Settings.webauthn.encoding.to_sym

  # サポートするアルゴリズム
  config.algorithms = Settings.webauthn.algorithms

  # デフォルトのRP（Relying Party）設定
  config.rp_name = Settings.webauthn.rp_name
  config.rp_id = Settings.webauthn.rp_id

  # Origin設定 (3.4.1では allowed_origins を使用)
  config.allowed_origins = [ Settings.webauthn.origin ]
end
