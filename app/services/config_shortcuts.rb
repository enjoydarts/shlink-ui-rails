# 設定値取得のショートカットメソッド集
# よく使う設定に対する便利なインターフェースを提供
module ConfigShortcuts
  # CAPTCHA設定
  def captcha_enabled?
    ApplicationConfig.enabled?("captcha.enabled", false)
  end

  def captcha_site_key
    ApplicationConfig.string("captcha.site_key")
  end

  def captcha_secret_key
    ApplicationConfig.string("captcha.secret_key")
  end

  def captcha_timeout
    ApplicationConfig.number("captcha.timeout", 10)
  end

  # Rate Limiting設定
  def rate_limit_enabled?
    ApplicationConfig.enabled?("rate_limit.enabled", true)
  end

  def login_rate_limit
    ApplicationConfig.number("rate_limit.login.requests_per_hour", 10)
  end

  def registration_rate_limit
    ApplicationConfig.number("rate_limit.registration.requests_per_hour", 5)
  end

  def url_creation_rate_limit
    ApplicationConfig.number("rate_limit.url_creation.requests_per_minute", 10)
  end

  # Email設定
  def email_adapter
    ApplicationConfig.string("email.adapter", "smtp")
  end

  def email_from_address
    ApplicationConfig.string("email.from_address")
  end

  def smtp_settings
    {
      address: ApplicationConfig.string("email.smtp_address"),
      port: ApplicationConfig.number("email.smtp_port", 587),
      user_name: ApplicationConfig.string("email.smtp_user_name"),
      password: ApplicationConfig.string("email.smtp_password"),
      authentication: ApplicationConfig.string("email.smtp_authentication", "plain"),
      enable_starttls_auto: ApplicationConfig.enabled?("email.smtp_enable_starttls_auto", true)
    }
  end

  def mailersend_api_key
    ApplicationConfig.string("email.mailersend_api_key")
  end

  # Shlink API設定
  def shlink_base_url
    ApplicationConfig.string("shlink.base_url", Settings.shlink.base_url)
  end

  def shlink_api_key
    ApplicationConfig.string("shlink.api_key", Settings.shlink.api_key)
  end

  def shlink_timeout
    ApplicationConfig.number("shlink.timeout", Settings.shlink.timeout || 30)
  end

  def shlink_retry_attempts
    ApplicationConfig.number("shlink.retry_attempts", Settings.shlink.retry_attempts || 3)
  end

  # Performance設定
  def performance_cache_ttl
    ApplicationConfig.number("performance.cache_ttl", 300)
  end

  def performance_database_pool_size
    ApplicationConfig.number("performance.database_pool_size", 5)
  end

  def performance_background_job_threads
    ApplicationConfig.number("performance.background_job_threads", 2)
  end

  # Security設定
  def security_require_2fa?
    ApplicationConfig.enabled?("security.require_2fa", false)
  end

  def security_session_timeout
    ApplicationConfig.number("security.session_timeout", 7200) # 2時間
  end

  def security_password_complexity_enabled?
    ApplicationConfig.enabled?("security.password_complexity", false)
  end

  # System設定
  def system_timezone
    ApplicationConfig.string("system.timezone", "Asia/Tokyo")
  end

  def system_log_level
    ApplicationConfig.string("system.log_level", "info")
  end

  def system_maintenance_mode?
    ApplicationConfig.enabled?("system.maintenance_mode", false)
  end

  # Redis設定
  def redis_url
    ApplicationConfig.string("redis.url", Settings.redis&.url || "redis://redis:6379/0")
  end

  def redis_timeout
    ApplicationConfig.number("redis.timeout", Settings.redis&.timeout || 5)
  end

  def redis_pool_size
    ApplicationConfig.number("redis.pool_size", Settings.redis&.pool_size || 5)
  end

  # WebAuthn設定
  def webauthn_rp_name
    ApplicationConfig.string("webauthn.rp_name", Settings.webauthn&.rp_name || "Shlink-UI-Rails")
  end

  def webauthn_rp_id
    ApplicationConfig.string("webauthn.rp_id", Settings.webauthn&.rp_id || "localhost")
  end

  def webauthn_origin
    ApplicationConfig.string("webauthn.origin", Settings.webauthn&.origin || "http://localhost:3000")
  end

  # アプリケーション設定
  def pagination_per_page
    ApplicationConfig.number("app.pagination.per_page", Settings.app&.pagination&.per_page || 20)
  end

  def pagination_max_per_page
    ApplicationConfig.number("app.pagination.max_per_page", Settings.app&.pagination&.max_per_page || 100)
  end

  def short_url_max_tags
    ApplicationConfig.number("app.short_url.max_tags", Settings.app&.short_url&.max_tags || 10)
  end

  def short_url_max_tag_length
    ApplicationConfig.number("app.short_url.max_tag_length", Settings.app&.short_url&.max_tag_length || 20)
  end

  # 設定のまとめて取得
  def captcha_config
    ApplicationConfig.category("captcha")
  end

  def rate_limit_config
    ApplicationConfig.category("rate_limit")
  end

  def email_config
    ApplicationConfig.category("email")
  end

  def performance_config
    ApplicationConfig.category("performance")
  end

  def security_config
    ApplicationConfig.category("security")
  end

  def system_config
    ApplicationConfig.category("system")
  end
end
