class ApplicationController < ActionController::Base
  # Allow modern browsers with mobile support
  # Note: モバイルでの利用を考慮してバージョン制限を緩和
  allow_browser versions: Settings.browser_support.to_h

  protect_from_forgery with: :exception, prepend: true

  # Letter Opener WebをCSRF保護から除外（開発環境のみ）
  skip_before_action :verify_authenticity_token, if: -> { Rails.env.development? && request.path.start_with?("/letter_opener") }

  # 統一設定システムを全コントローラーで使用可能にする
  include ConfigShortcuts
  include SystemSettingsHelper
  helper_method :system_setting, :site_name, :site_url, :maintenance_mode?,
                :captcha_enabled?, :rate_limit_enabled?, :page_size,
                :password_min_length, :require_2fa_for_admin?,
                :max_short_urls_per_user, :default_short_code_length,
                :allowed_domains, :current_version, :deploy_time

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_maintenance_mode, unless: :devise_controller?
  before_action :detect_coffee_request

  # Deviseの認証後リダイレクト先を設定
  def after_sign_in_path_for(resource)
    if resource.admin?
      admin_dashboard_path
    else
      dashboard_path
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  # 現在のコミットハッシュを取得
  def current_version
    @current_version ||= begin
      if Rails.env.production?
        # 本番環境：環境変数から取得、なければgitコマンドで取得
        ENV["GIT_COMMIT"] || `git rev-parse --short HEAD 2>/dev/null`.strip.presence || "unknown"
      else
        # 開発環境：gitコマンドで取得
        `git rev-parse --short HEAD 2>/dev/null`.strip.presence || "unknown"
      end
    end
  end

  # デプロイ時刻を取得
  def deploy_time
    @deploy_time ||= begin
      if Rails.env.production?
        # 本番環境：環境変数BUILD_TIMEから取得、なければコミット日時
        if ENV["BUILD_TIME"].present?
          Time.parse(ENV["BUILD_TIME"]).in_time_zone("Asia/Tokyo")
        elsif ENV["GIT_COMMIT"].present?
          # gitコマンドでコミット日時を取得（セキュアに実行）
          git_commit = ENV["GIT_COMMIT"].to_s.strip
          # コミットハッシュの形式を検証（7-40文字の英数字のみ）
          if git_commit.match?(/\A[a-f0-9]{7,40}\z/i)
            commit_time = `git show -s --format=%ci #{git_commit} 2>/dev/null`.strip
            commit_time.present? ? Time.parse(commit_time).in_time_zone("Asia/Tokyo") : Time.current
          else
            Time.current
          end
        else
          Time.current
        end
      else
        # 開発環境：最新コミットの日時（セキュアに実行）
        begin
          commit_time = `git show -s --format=%ci HEAD 2>/dev/null`.strip
          commit_time.present? ? Time.parse(commit_time).in_time_zone("Asia/Tokyo") : Time.current
        rescue => e
          Rails.logger.warn "Failed to get commit time: #{e.message}"
          Time.current
        end
      end
    end
  end

  private

  def check_maintenance_mode
    return unless maintenance_mode?
    return if current_user&.admin? # 管理者は除外

    render "errors/maintenance", status: :service_unavailable
  end

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

  # RFC 2324 Easter Egg: コーヒー関連のリクエストを検出
  def detect_coffee_request
    # 開発環境でのみ動作（本番では無効化）
    return unless Rails.env.development?

    # 特定のルートは除外
    return if controller_name == "pages" && action_name == "teapot"
    return if request.path.start_with?("/assets/") || request.path.start_with?("/letter_opener")

    coffee_keywords = %w[coffee espresso latte cappuccino mocha americano macchiato frappuccino brew]

    # URL、パラメータ、ヘッダーからコーヒー関連キーワードを検出
    coffee_detected = coffee_keywords.any? do |keyword|
      request.path.downcase.include?(keyword) ||
      request.query_string.downcase.include?(keyword) ||
      params.values.join(" ").downcase.include?(keyword) ||
      request.headers["User-Agent"]&.downcase&.include?(keyword)
    end

    if coffee_detected
      Rails.logger.info "☕ Coffee detected! Redirecting to teapot: #{request.fullpath}"
      redirect_to "/teapot" and return
    end
  end
end
