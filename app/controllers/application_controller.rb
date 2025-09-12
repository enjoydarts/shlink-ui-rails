class ApplicationController < ActionController::Base
  # Allow modern browsers with mobile support
  # Note: モバイルでの利用を考慮してバージョン制限を緩和
  allow_browser versions: Settings.browser_support.to_h

  protect_from_forgery with: :exception, prepend: true

  before_action :configure_permitted_parameters, if: :devise_controller?

  # Deviseの認証後リダイレクト先を設定
  def after_sign_in_path_for(resource)
    dashboard_path
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  # CAPTCHA検証ヘルパーメソッド
  # @param token [String] Turnstileトークン
  # @return [Boolean] 検証成功の場合true
  def verify_captcha(token = nil)
    # CAPTCHAが無効な場合はスキップ
    return true if CaptchaHelper.disabled?

    # トークンが引数で渡されない場合はパラメータから取得
    # Deviseパラメータ、直接パラメータ、ダッシュ形式の順でチェック
    unless token
      # Deviseのresource_nameが利用可能な場合（devise_controller?の場合）
      if respond_to?(:resource_name) && resource_name
        token = params.dig(resource_name, :cf_turnstile_response)
      end
      
      # Deviseパラメータで見つからない場合は直接パラメータから取得
      token ||= params[:cf_turnstile_response] || params["cf-turnstile-response"]
    end

    result = CaptchaVerificationService.verify(
      token: token,
      remote_ip: request.remote_ip
    )

    unless result.success?
      Rails.logger.warn "CAPTCHA verification failed: #{result.error_codes.join(', ')}"
      flash.now[:alert] = captcha_error_message(result.error_codes)
    end

    result.success?
  end

  # CAPTCHAエラーメッセージの生成
  # @param error_codes [Array<String>] エラーコード配列
  # @return [String] ユーザー向けエラーメッセージ
  def captcha_error_message(error_codes)
    return "セキュリティ検証に失敗しました。しばらく時間をおいて再度お試しください。" if error_codes.include?("timeout")
    return "セキュリティ検証でエラーが発生しました。ページを再読み込みして再度お試しください。" if error_codes.include?("network-error")

    "セキュリティ検証が完了していません。チェックボックスにチェックを入れてから送信してください。"
  end
end
