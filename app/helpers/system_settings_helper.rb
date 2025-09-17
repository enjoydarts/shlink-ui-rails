module SystemSettingsHelper
  # システム設定を取得するヘルパーメソッド
  def system_setting(key, default = nil)
    cache_ttl = SystemSetting.get("performance.cache_ttl", 3600).to_i
    Rails.cache.fetch("system_setting:#{key}", expires_in: cache_ttl.seconds) do
      SystemSetting.get(key, default)
    end
  end

  # サイト名を取得
  def site_name
    system_setting("system.site_name", "Shlink-UI-Rails")
  end

  # サイトURLを取得
  def site_url
    system_setting("system.site_url", request.base_url)
  end

  # メンテナンスモードかどうか確認
  def maintenance_mode?
    system_setting("system.maintenance_mode", false)
  end

  # CAPTCHAが有効かどうか確認
  def captcha_enabled?
    system_setting("captcha.enabled", false)
  end

  # レート制限が有効かどうか確認
  def rate_limit_enabled?
    system_setting("rate_limit.enabled", true)
  end

  # ページサイズを取得
  def page_size
    system_setting("performance.page_size", 20)
  end

  # パスワード最小長を取得
  def password_min_length
    system_setting("security.password_min_length", 8)
  end

  # 2FA必須かどうか確認（管理者向け）
  def require_2fa_for_admin?
    system_setting("security.require_2fa_for_admin", true)
  end

  # ユーザーあたりの最大短縮URL数を取得
  def max_short_urls_per_user
    system_setting("performance.max_short_urls_per_user", 1000)
  end

  # デフォルト短縮コード長を取得
  def default_short_code_length
    system_setting("system.default_short_code_length", 5)
  end

  # 許可ドメイン一覧を取得
  def allowed_domains
    system_setting("system.allowed_domains", [])
  end

  # システム設定の変更を反映（キャッシュクリア）
  def refresh_system_settings!
    Rails.cache.delete_matched("system_setting:*")
  end

  # SMTP設定をハッシュ形式で取得
  def smtp_settings_hash
    {
      address: system_setting("email.smtp_address", "smtp.gmail.com"),
      port: system_setting("email.smtp_port", 587),
      user_name: system_setting("email.smtp_user_name", ""),
      password: system_setting("email.smtp_password", ""),
      authentication: system_setting("email.smtp_authentication", "plain"),
      enable_starttls_auto: system_setting("email.smtp_enable_starttls_auto", true)
    }.compact
  end

  # メール送信元アドレスを取得
  def email_from_address
    system_setting("email.from_address", "noreply@example.com")
  end

  # メール送信アダプターを取得
  def email_adapter
    system_setting("email.adapter", "smtp")
  end

  # システム設定変更後のキャッシュクリアとActionMailer再設定
  def refresh_system_settings!
    # システム設定のキャッシュをクリア
    Rails.cache.delete_matched("system_setting:*")

    # 各種設定を即座に反映
    if defined?(Rails::Application)
      Rails.logger.info "システム設定変更に伴い各種設定を再読み込みします"

      # タイムゾーン設定の更新
      timezone = SystemSetting.get("system.timezone", "Asia/Tokyo")
      Time.zone = timezone
      Rails.logger.info "タイムゾーンを更新: #{Time.zone}"

      # ログレベル設定の更新
      log_level = SystemSetting.get("system.log_level", "info")
      Rails.logger.level = case log_level.downcase
      when "debug" then Logger::DEBUG
      when "info" then Logger::INFO
      when "warn" then Logger::WARN
      when "error" then Logger::ERROR
      when "fatal" then Logger::FATAL
      else Logger::INFO
      end
      Rails.logger.info "ログレベルを更新: #{Rails.logger.level}"

      # データベースタイムアウト設定の更新
      timeout_seconds = SystemSetting.get("performance.database_timeout", 30)
      begin
        ActiveRecord::Base.connection_pool.with_connection do |conn|
          conn.execute("SET SESSION wait_timeout = #{timeout_seconds}")
          conn.execute("SET SESSION interactive_timeout = #{timeout_seconds}")
        end
        Rails.logger.info "データベースタイムアウトを更新: #{timeout_seconds}秒"
      rescue => e
        Rails.logger.warn "データベースタイムアウト設定の更新に失敗: #{e.message}"
      end

      # Devise設定の更新
      if defined?(Devise)
        devise_max_attempts = SystemSetting.get("security.max_login_attempts", 5)
        Devise.maximum_attempts = devise_max_attempts.to_i

        unlock_time = SystemSetting.get("security.account_lockout_time", 30)
        Devise.unlock_in = unlock_time.to_i.minutes

        password_min_length = SystemSetting.get("security.password_min_length", 8)
        Devise.password_length = password_min_length.to_i..128

        session_timeout = SystemSetting.get("security.session_timeout_hours", 24)
        Devise.timeout_in = session_timeout.to_i.hours

        Rails.logger.info "Devise設定を更新"
      end

      # ActionMailer設定を再読み込み
      email_adapter_setting = SystemSetting.get("email.adapter", "smtp")
      case email_adapter_setting.downcase
      when "letter_opener"
        Rails.application.config.action_mailer.delivery_method = :letter_opener
      when "mailersend"
        Rails.application.config.action_mailer.delivery_method = :mailersend
        # MailerSend API設定の更新
        mailersend_api_key = SystemSetting.get("email.mailersend_api_key", "")
        if defined?(MailerSend)
          MailerSend.configuration.api_key = mailersend_api_key if mailersend_api_key.present?
        end
      else
        Rails.application.config.action_mailer.delivery_method = :smtp
        Rails.application.config.action_mailer.smtp_settings = smtp_settings_hash
      end

      Rails.application.config.action_mailer.default_options = {
        from: email_from_address
      }

      Rails.logger.info "ActionMailer配信方法を更新: #{email_adapter_setting}"

      # デフォルトURL設定の更新
      site_url_setting = system_setting("system.site_url", request&.base_url || "http://localhost:3000")
      uri = URI.parse(site_url_setting)

      Rails.application.config.action_mailer.default_url_options = {
        host: uri.host,
        port: uri.port,
        protocol: uri.scheme
      }

      Rails.logger.info "全設定の再読み込みが完了しました"
    end
  rescue StandardError => e
    Rails.logger.error "システム設定の再読み込み中にエラーが発生: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end
end
