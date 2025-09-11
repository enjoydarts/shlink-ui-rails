# frozen_string_literal: true

class WebauthnService
  class << self
    # WebAuthnライブラリの設定を取得
    def webauthn_config
      @webauthn_config ||= WebAuthn.configuration.tap do |config|
        config.origin = Rails.application.config.webauthn_origin || "http://localhost:3000"
        config.rp_name = Rails.application.config.webauthn_rp_name || "Shlink-UI-Rails"
        config.rp_id = Rails.application.config.webauthn_rp_id || "localhost"
      end
    end

    # 登録用のオプションを生成
    # @param user [User] 対象ユーザー
    # @return [Hash] WebAuthn登録オプション
    def registration_options(user)
      # 既存のクレデンシャルを除外リストに追加
      exclude_credentials = user.webauthn_credentials.active.map do |cred|
        { id: cred.external_id, type: "public-key" }
      end

      options = WebAuthn::Credential.options_for_create(
        user: {
          id: user.webauthn_id,
          name: user.email,
          display_name: user.display_name
        },
        exclude: exclude_credentials,
        authenticator_selection: {
          user_verification: "preferred",
          resident_key: "preferred"
        }
      )

      {
        challenge: Base64.urlsafe_encode64(options.challenge),
        rp: options.rp,
        user: {
          id: Base64.urlsafe_encode64(options.user[:id]),
          name: options.user[:name],
          display_name: options.user[:display_name]
        },
        pub_key_cred_params: options.pub_key_cred_params,
        exclude_credentials: exclude_credentials.map { |cred|
          { id: Base64.urlsafe_encode64(cred[:id]), type: cred[:type] }
        },
        authenticator_selection: options.authenticator_selection,
        timeout: 60000
      }
    end

    # 認証用のオプションを生成
    # @param user [User] 対象ユーザー
    # @return [Hash] WebAuthn認証オプション
    def authentication_options(user)
      # 利用可能なクレデンシャルをリストアップ
      allow_credentials = user.active_webauthn_credentials.map do |cred|
        { id: cred.external_id, type: "public-key" }
      end

      options = WebAuthn::Credential.options_for_get(
        allow: allow_credentials,
        user_verification: "preferred"
      )

      {
        challenge: Base64.urlsafe_encode64(options.challenge),
        allow_credentials: allow_credentials.map { |cred|
          { id: Base64.urlsafe_encode64(cred[:id]), type: cred[:type] }
        },
        timeout: 60000,
        user_verification: "preferred"
      }
    end

    # クレデンシャルを登録
    # @param user [User] 対象ユーザー
    # @param credential_response [Hash] WebAuthnクライアントからのレスポンス
    # @param challenge [String] 登録時のチャレンジ
    # @param nickname [String] クレデンシャルのニックネーム
    # @return [WebauthnCredential] 作成されたクレデンシャル
    def register_credential(user, credential_response, challenge, nickname: nil)
      webauthn_credential = WebAuthn::Credential.from_create(credential_response)

      # チャレンジを検証
      webauthn_credential.verify(Base64.urlsafe_decode64(challenge))

      # データベースに保存
      user.webauthn_credentials.create!(
        external_id: webauthn_credential.id,
        public_key: webauthn_credential.public_key,
        sign_count: webauthn_credential.sign_count,
        nickname: nickname || generate_default_nickname(user),
        active: true
      )
    rescue WebAuthn::Error => e
      Rails.logger.error "WebAuthn registration failed: #{e.message}"
      raise StandardError, "セキュリティキーの登録に失敗しました"
    end

    # 認証を検証
    # @param user [User] 対象ユーザー
    # @param credential_response [Hash] WebAuthnクライアントからのレスポンス
    # @param challenge [String] 認証時のチャレンジ
    # @return [Boolean] 認証成功の場合true
    def verify_authentication(user, credential_response, challenge)
      webauthn_credential = WebAuthn::Credential.from_get(credential_response)

      # 対応するクレデンシャルをデータベースから取得
      stored_credential = user.active_webauthn_credentials.find_by(
        external_id: webauthn_credential.id
      )

      return false unless stored_credential

      # WebAuthn検証
      webauthn_credential.verify(
        Base64.urlsafe_decode64(challenge),
        public_key: stored_credential.public_key,
        sign_count: stored_credential.sign_count
      )

      # 成功した場合、使用履歴を更新
      stored_credential.update!(
        sign_count: webauthn_credential.sign_count,
        last_used_at: Time.current
      )

      true
    rescue WebAuthn::Error => e
      Rails.logger.error "WebAuthn authentication failed: #{e.message}"
      false
    end

    # クレデンシャルを削除
    # @param user [User] 対象ユーザー
    # @param credential_id [Integer] クレデンシャルID
    # @return [Boolean] 削除成功の場合true
    def remove_credential(user, credential_id)
      credential = user.webauthn_credentials.find(credential_id)
      credential.destroy!
      true
    rescue ActiveRecord::RecordNotFound
      false
    end

    private

    # デフォルトのニックネームを生成
    # @param user [User] 対象ユーザー
    # @return [String] デフォルトニックネーム
    def generate_default_nickname(user)
      count = user.webauthn_credentials.count + 1
      "セキュリティキー #{count}"
    end
  end
end
