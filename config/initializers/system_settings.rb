# SystemSettingとActionMailerの統合
Rails.application.reloader.to_prepare do
  begin
    # システム設定が存在する場合のみ設定を上書き
    if ActiveRecord::Base.connection.table_exists?("system_settings") && defined?(SystemSetting)
      # メール設定の動的反映（全環境共通）
      email_adapter = SystemSetting.get("email.adapter", Rails.env.development? ? "letter_opener" : "smtp")

      case email_adapter
      when "letter_opener"
        # Letter Opener (開発用)
        Rails.application.config.action_mailer.delivery_method = :letter_opener_web
        Rails.application.config.action_mailer.perform_deliveries = true
      when "smtp"
        Rails.application.config.action_mailer.delivery_method = :smtp
        Rails.application.config.action_mailer.smtp_settings = {
          address: SystemSetting.get("email.smtp_address", "smtp.gmail.com"),
          port: SystemSetting.get("email.smtp_port", 587),
          user_name: SystemSetting.get("email.smtp_user_name", ""),
          password: SystemSetting.get("email.smtp_password", ""),
          authentication: SystemSetting.get("email.smtp_authentication", "plain").to_sym,
          enable_starttls_auto: SystemSetting.get("email.smtp_enable_starttls_auto", true)
        }.compact
      when "mailersend"
        # MailerSendは独自のAPIを使用するため、Rails標準の:smtpを設定
        # 実際の送信はMailAdapterで制御される
        Rails.application.config.action_mailer.delivery_method = :smtp
        Rails.application.config.action_mailer.perform_deliveries = true
      else
        # 未知のアダプタの場合はデフォルトを使用
        Rails.application.config.action_mailer.delivery_method = Rails.env.development? ? :letter_opener_web : :smtp
        Rails.application.config.action_mailer.perform_deliveries = true
      end

      # デフォルト送信者アドレスの設定
      Rails.application.config.action_mailer.default_options = {
        from: SystemSetting.get("email.from_address", "noreply@example.com")
      }

      # サイトURLの動的設定
      site_url = SystemSetting.get("system.site_url", "http://localhost:3000")
      uri = URI.parse(site_url)

      Rails.application.config.action_mailer.default_url_options = {
        host: uri.host,
        port: uri.port,
        protocol: uri.scheme
      }
    end
  rescue ActiveRecord::StatementInvalid, ActiveRecord::ConnectionNotEstablished => e
    # データベースがまだ作成されていない場合やマイグレーション実行前はスキップ
    Rails.logger.info "SystemSettings table not available, using default configuration: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Error loading system settings: #{e.message}"
  end
end
