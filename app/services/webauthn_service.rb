# frozen_string_literal: true

require "webauthn"

class WebauthnService
  class << self
    # WebAuthn設定値を取得
    def rp_name
      Settings.webauthn.rp_name
    end

    def rp_id
      Settings.webauthn.rp_id
    end

    def origin
      Settings.webauthn.origin
    end

    # 登録用のオプションを生成
    # @param user [User] 対象ユーザー
    # @return [Hash] WebAuthn登録オプション
    def registration_options(user)
      # 既存のクレデンシャルを除外リストに追加
      exclude_credentials = user.webauthn_credentials.active.map(&:external_id)
      Rails.logger.debug "WebAuthn registration - Excluding credentials: #{exclude_credentials.inspect}"

      # WebAuthn 3.4.1の正しいAPIを使用
      options = WebAuthn::Credential.options_for_create(
        user: {
          id: Base64.urlsafe_encode64(user.webauthn_id),
          name: user.email,
          display_name: user.display_name || user.email
        },
        exclude: exclude_credentials,
        authenticator_selection: {
          user_verification: "preferred",
          resident_key: "preferred"
        },
        rp: { id: rp_id, name: rp_name },
        extensions: {},
        timeout: Settings.webauthn.timeout
      )

      # Rails controllerでJSONレンダリング可能な形式で返す
      options.as_json
    end

    # 認証用のオプションを生成
    # @param user [User] 対象ユーザー
    # @return [Hash] WebAuthn認証オプション
    def authentication_options(user)
      # 利用可能なクレデンシャルをリストアップ
      allow_credentials = user.webauthn_credentials.active.map(&:external_id)

      # WebAuthn 3.4.1の正しいAPIを使用
      options = WebAuthn::Credential.options_for_get(
        allow: allow_credentials,
        user_verification: "preferred",
        timeout: Settings.webauthn.timeout
      )

      # rpIdを明示的に追加
      result = options.as_json
      result["rpId"] = rp_id
      result
    end

    # クレデンシャルを登録
    # @param user [User] 対象ユーザー
    # @param credential_response [Hash] WebAuthnクライアントからのレスポンス
    # @param challenge [String] 登録時のチャレンジ
    # @param nickname [String] クレデンシャルのニックネーム
    # @return [WebauthnCredential] 作成されたクレデンシャル
    def register_credential(user, credential_response, challenge, nickname: nil)
      Rails.logger.debug "WebAuthn registration - RP ID: #{rp_id}, Origin: #{origin}"
      Rails.logger.debug "WebAuthn registration - Challenge: #{challenge}"

      # WebAuthn 3.4.1の正しいAPIを使用
      webauthn_credential = WebAuthn::Credential.from_create(credential_response)

      # 検証を実行（設定されたRP IDとOriginを使用）
      webauthn_credential.verify(challenge)

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
      Rails.logger.debug "WebAuthn error class: #{e.class}"
      Rails.logger.debug "WebAuthn error full: #{e.inspect}"

      # エラーメッセージに基づいてユーザーフレンドリーなメッセージを返す
      error_message = case e.message
      when /already registered/, /contains one of the credentials already registered/
        "このセキュリティキーは既に登録されています。別のセキュリティキーを使用してください。"
      when /timeout/, /timed out/
        "セキュリティキーの操作がタイムアウトしました。再度お試しください。"
      when /not allowed/, /NotAllowedError/
        "セキュリティキーの操作が許可されませんでした。再度お試しください。"
      when /invalid/, /verification failed/
        "セキュリティキーの検証に失敗しました。正しいセキュリティキーを使用してください。"
      else
        "セキュリティキーの登録に失敗しました。"
      end

      Rails.logger.debug "Converted error message: #{error_message}"
      raise StandardError, error_message
    end

    # 認証を検証
    # @param user [User] 対象ユーザー
    # @param credential_response [Hash] WebAuthnクライアントからのレスポンス
    # @param challenge [String] 認証時のチャレンジ
    # @return [Boolean] 認証成功の場合true
    def verify_authentication(user, credential_response, challenge)
      # データベースからクレデンシャルを取得
      credential_id = credential_response["id"]
      stored_credential = user.webauthn_credentials.active.find_by(external_id: credential_id)

      return false unless stored_credential


      # WebAuthn 3.4.1の正しいAPIを使用
      webauthn_credential = WebAuthn::Credential.from_get(credential_response)

      # 検証を実行（設定されたRP IDとOriginを使用）
      webauthn_credential.verify(
        challenge,
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
