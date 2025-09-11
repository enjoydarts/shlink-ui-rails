module CaptchaHelper
  # CAPTCHA機能が有効かどうかを判定
  # @return [Boolean] 有効の場合true
  def self.enabled?
    !disabled?
  end

  # CAPTCHA機能が無効かどうかを判定
  # @return [Boolean] 無効の場合true
  def self.disabled?
    Rails.env.test? ||
      Settings.captcha.turnstile.site_key.blank? ||
      Settings.captcha.turnstile.secret_key.blank?
  end

  # CAPTCHA設定が完全に設定されているかを判定
  # @return [Boolean] 完全設定の場合true
  def self.configured?
    Settings.captcha.turnstile.site_key.present? &&
      Settings.captcha.turnstile.secret_key.present? &&
      Settings.captcha.turnstile.verify_url.present?
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
end
