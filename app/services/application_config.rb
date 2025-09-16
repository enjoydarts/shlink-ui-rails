# 統一された設定管理システム
# 優先順位: SystemSetting (DB) > 環境変数 > config gem > デフォルト値
class ApplicationConfig
  class << self
    # 全設定を動的にリロード（SystemSetting変更時に呼び出される）
    def reload_all_settings!
      return unless Rails.application.initialized?

      begin
        reload_action_mailer_settings!
        reload_rack_attack_settings!
        reload_devise_settings!
        reload_database_settings!
        reload_rails_core_settings!
        reload_shlink_settings!
        reload_captcha_settings!
        reload_application_features!

        # 最後に一括でキャッシュクリア
        clear_cache!
        Rails.logger.info "All application settings reloaded successfully"
      rescue => e
        Rails.logger.error "Failed to reload settings: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end

    # メイン設定取得メソッド
    def get(key, default_value = nil)
      # 1. SystemSetting (データベース) - 最高優先度
      if defined?(SystemSetting) && SystemSetting.table_exists?
        db_value = SystemSetting.get(key)
        return db_value if db_value.present?
      end

      # 2. 環境変数 - 第2優先度
      env_key = key.upcase.gsub(".", "_")
      env_value = ENV[env_key]
      return parse_env_value(env_value) if env_value.present?

      # 3. config gem - 第3優先度
      config_value = get_from_settings(key)
      return config_value if config_value.present?

      # 4. デフォルト値
      default_value
    rescue => e
      Rails.logger.error "ApplicationConfig.get error for key '#{key}': #{e.message}"
      default_value
    end

    # boolean設定専用メソッド
    def enabled?(key, default = false)
      value = get(key, default)
      case value
      when String
        %w[true 1 yes on enabled].include?(value.downcase)
      when Integer
        value > 0
      else
        !!value
      end
    end

    # 数値設定専用メソッド
    def number(key, default = 0)
      get(key, default).to_i
    end

    # 文字列設定専用メソッド
    def string(key, default = "")
      get(key, default).to_s
    end

    # 配列設定専用メソッド
    def array(key, default = [])
      value = get(key, default)
      case value
      when Array
        value
      when String
        begin
          JSON.parse(value)
        rescue JSON::ParserError
          value.split(",").map(&:strip)
        end
      else
        Array(value)
      end
    end

    # カテゴリごとの設定を一括取得
    def category(category_name)
      result = {}

      # SystemSettingから取得
      if defined?(SystemSetting) && SystemSetting.table_exists?
        SystemSetting.by_category(category_name).enabled.each do |setting|
          result[setting.key_name] = setting.typed_value
        end
      end

      # config gemから補完
      get_category_from_settings(category_name).each do |key, value|
        result[key] ||= value
      end

      result
    end

    # 設定値を更新（SystemSettingに保存）
    def set(key, value, type: "string", category: nil, description: nil)
      return false unless defined?(SystemSetting) && SystemSetting.table_exists?

      SystemSetting.set(key, value, {
        type: type,
        category: category,
        description: description
      })

      # キャッシュクリア
      clear_cache!
      true
    rescue => e
      Rails.logger.error "ApplicationConfig.set error for key '#{key}': #{e.message}"
      false
    end

    # 設定のリセット（SystemSettingから削除してデフォルトに戻す）
    def reset(key)
      return false unless defined?(SystemSetting) && SystemSetting.table_exists?

      SystemSetting.where(key_name: key).destroy_all
      clear_cache!
      true
    rescue => e
      Rails.logger.error "ApplicationConfig.reset error for key '#{key}': #{e.message}"
      false
    end

    # システム設定の初期化
    def initialize_defaults!
      return false unless defined?(SystemSetting)

      SystemSetting.initialize_defaults!
      clear_cache!
      true
    end

    # 設定変更通知（アプリケーション設定を再読み込み）
    def reload!
      # タイムゾーン設定
      Time.zone = get("system.timezone", "Tokyo")

      # ログレベル設定
      log_level = get("system.log_level", "info")
      Rails.logger.level = case log_level.downcase
      when "debug" then Logger::DEBUG
      when "info" then Logger::INFO
      when "warn" then Logger::WARN
      when "error" then Logger::ERROR
      when "fatal" then Logger::FATAL
      else Logger::INFO
      end

      # キャッシュクリア
      clear_cache!
      Rails.logger.info "ApplicationConfig reloaded: timezone=#{Time.zone}, log_level=#{Rails.logger.level}"
      true
    rescue => e
      Rails.logger.error "ApplicationConfig.reload! error: #{e.message}"
      false
    end

    private

    # ActionMailer設定のリロード
    def reload_action_mailer_settings!
      # サイトURL設定
      site_url = get("system.site_url", "http://localhost:3000")
      uri = URI.parse(site_url)

      Rails.application.config.action_mailer.default_url_options = {
        host: uri.host,
        port: uri.port,
        protocol: uri.scheme
      }

      # 送信者設定
      Rails.application.config.action_mailer.default_options = {
        from: get("email.from_address", "noreply@example.com")
      }

      # SMTP設定
      email_adapter = get("email.adapter", Rails.env.development? ? "letter_opener" : "smtp")

      case email_adapter
      when "letter_opener"
        Rails.application.config.action_mailer.delivery_method = :letter_opener_web
        Rails.application.config.action_mailer.perform_deliveries = true
      when "smtp"
        Rails.application.config.action_mailer.delivery_method = :smtp
        Rails.application.config.action_mailer.smtp_settings = {
          address: get("email.smtp_address", "smtp.gmail.com"),
          port: get("email.smtp_port", 587),
          user_name: get("email.smtp_user_name", ""),
          password: get("email.smtp_password", ""),
          authentication: get("email.smtp_authentication", "plain").to_sym,
          enable_starttls_auto: get("email.smtp_enable_starttls_auto", true)
        }.compact
      when "mailersend"
        # MailerSendは独自のAPIを使用するため、delivery_methodは設定しない
        # 実際の送信はMailAdapter::MailersendAdapterが処理
        Rails.application.config.action_mailer.perform_deliveries = true
      end
    end

    # Rack::Attack設定のリロード
    def reload_rack_attack_settings!
      return unless defined?(Rack::Attack)

      # Rack::Attackの設定をクリア
      Rack::Attack.reset!

      # 設定ファイルを再読み込み
      load Rails.root.join("config/initializers/rack_attack.rb")
    end

    # Devise設定のリロード
    def reload_devise_settings!
      return unless defined?(Devise)

      # Devise設定の更新
      Devise.setup do |config|
        config.maximum_attempts = get("security.max_login_attempts", 5)
        config.unlock_in = get("security.account_lockout_time", 30).minutes
        config.password_length = get("security.password_min_length", 8)..128
        config.timeout_in = get("security.session_timeout_hours", 24).hours
      end
    end

    # データベース設定のリロード
    def reload_database_settings!
      timeout_seconds = get("performance.database_timeout", 30)

      # データベース接続プールの設定を更新
      ActiveRecord::Base.connection_pool.disconnect!
      Rails.application.config.database_configuration[Rails.env]["timeout"] = timeout_seconds * 1000
      ActiveRecord::Base.establish_connection
    end

    # Rails核心設定のリロード
    def reload_rails_core_settings!
      # タイムゾーン設定
      timezone = get("system.timezone", "Tokyo")
      Time.zone = timezone if ActiveSupport::TimeZone[timezone]

      # ログレベル設定
      log_level = get("system.log_level", "info").downcase
      if %w[debug info warn error fatal].include?(log_level)
        Rails.logger.level = log_level.to_sym
      end
    end

    # Shlink設定のリロード
    def reload_shlink_settings!
      # Shlink設定はサービスクラスで動的に取得されるため、ログ出力のみ
      Rails.logger.info "Shlink settings marked for reload"
    end

    # CAPTCHA設定のリロード
    def reload_captcha_settings!
      # CAPTCHA設定もサービスクラスで動的に取得されるため、ログ出力のみ
      Rails.logger.info "CAPTCHA settings marked for reload"
    end

    # アプリケーション機能設定のリロード
    def reload_application_features!
      # メンテナンスモード設定
      maintenance_mode = enabled?("system.maintenance_mode", false)
      if maintenance_mode
        # メンテナンスモードの実装（必要に応じて）
        Rails.logger.info "Maintenance mode enabled"
      else
        Rails.logger.info "Maintenance mode disabled"
      end

      # ユーザー登録許可設定
      allow_registration = enabled?("system.allow_user_registration", true)
      Rails.logger.info "User registration: #{allow_registration ? 'enabled' : 'disabled'}"

      # パフォーマンス設定
      Rails.logger.info "Items per page: #{number('performance.items_per_page', 20)}"
      Rails.logger.info "Cache TTL: #{number('performance.cache_ttl', 3600)} seconds"
    end

    # 設定キャッシュ（開発環境では無効、本番環境では有効）
    def cache_key(key)
      "app_config:#{key}"
    end

    def cached_get(key)
      return yield unless Rails.env.production?

      Rails.cache.fetch(cache_key(key), expires_in: 5.minutes) do
        yield
      end
    end

    def clear_cache!
      return unless Rails.env.production?

      Rails.cache.delete_matched("app_config:*")
    end

    # config gemから設定を取得
    def get_from_settings(key)
      keys = key.split(".")
      current = Settings

      keys.each do |k|
        return nil unless current.respond_to?(k)
        current = current.send(k)
      end

      current
    rescue => e
      Rails.logger.debug "Settings access error for key '#{key}': #{e.message}"
      nil
    end

    # config gemからカテゴリ設定を取得
    def get_category_from_settings(category)
      return {} unless Settings.respond_to?(category)

      category_settings = Settings.send(category)
      return {} unless category_settings.respond_to?(:to_h)

      flatten_hash(category_settings.to_h, "#{category}.")
    rescue => e
      Rails.logger.debug "Settings category access error for '#{category}': #{e.message}"
      {}
    end

    # ハッシュを平坦化
    def flatten_hash(hash, prefix = "")
      result = {}
      hash.each do |key, value|
        new_key = "#{prefix}#{key}"
        if value.is_a?(Hash)
          result.merge!(flatten_hash(value, "#{new_key}."))
        else
          result[new_key] = value
        end
      end
      result
    end

    # 環境変数の値を適切な型に変換
    def parse_env_value(value)
      # boolean
      return true if %w[true 1 yes on enabled].include?(value.downcase)
      return false if %w[false 0 no off disabled].include?(value.downcase)

      # number
      return value.to_i if value.match?(/^\d+$/)
      return value.to_f if value.match?(/^\d+\.\d+$/)

      # JSON
      begin
        return JSON.parse(value) if value.start_with?("{", "[")
      rescue JSON::ParserError
        # 文字列として扱う
      end

      # 文字列
      value
    end
  end
end
