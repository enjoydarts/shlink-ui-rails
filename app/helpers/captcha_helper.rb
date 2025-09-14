module CaptchaHelper
  # CAPTCHA機能が有効かどうかを判定
  # @return [Boolean] 有効の場合true
  def self.enabled?
    !disabled?
  end

  # CAPTCHA機能が無効かどうかを判定
  # @return [Boolean] 無効の場合true
  def self.disabled?
    return true if Rails.env.test?

    # システム設定から判定
    return true unless SystemSetting.get("captcha.enabled", false)

    # キーが設定されているかチェック
    site_key = SystemSetting.get("captcha.site_key", "")
    secret_key = SystemSetting.get("captcha.secret_key", "")

    site_key.blank? || secret_key.blank?
  end

  # CAPTCHA設定が完全に設定されているかを判定
  # @return [Boolean] 完全設定の場合true
  def self.configured?
    return false unless SystemSetting.get("captcha.enabled", false)

    site_key = SystemSetting.get("captcha.site_key", "")
    secret_key = SystemSetting.get("captcha.secret_key", "")

    site_key.present? && secret_key.present?
  end

  # 現在のリクエストでCAPTCHA検証が必要かを判定
  # @param controller [ActionController::Base] コントローラーインスタンス
  # @return [Boolean] 検証必要の場合true
  def self.required_for?(controller)
    return false unless enabled?

    # Deviseコントローラーの認証アクションで必要
    controller.is_a?(Devise::SessionsController) ||
      controller.is_a?(Devise::RegistrationsController)
  end

  # Turnstile Site Keyを取得
  # @return [String] Site Key
  def self.site_key
    SystemSetting.get("captcha.site_key", "")
  end

  # Turnstile Secret Keyを取得（内部使用のみ）
  # @return [String] Secret Key
  def self.secret_key
    SystemSetting.get("captcha.secret_key", "")
  end

  # CAPTCHA検証タイムアウト時間を取得
  # @return [Integer] タイムアウト時間（秒）
  def self.timeout
    SystemSetting.get("captcha.timeout", 10)
  end

  # CAPTCHA検証API URLを取得
  # @return [String] API URL
  def self.verify_url
    SystemSetting.get("captcha.verify_url", "https://challenges.cloudflare.com/turnstile/v0/siteverify")
  end
end
