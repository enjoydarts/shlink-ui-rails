class SystemSetting < ApplicationRecord
  validates :key_name, presence: true, uniqueness: true
  validates :setting_type, presence: true, inclusion: { in: %w[string integer boolean json array] }

  # 設定カテゴリの定数
  CATEGORIES = {
    shlink: "shlink",
    captcha: "captcha",
    rate_limit: "rate_limit",
    email: "email",
    performance: "performance",
    security: "security",
    system: "system",
    legal: "legal"
  }.freeze

  validates :category, inclusion: { in: CATEGORIES.values }, allow_blank: true
  validate :validate_setting_constraints

  scope :enabled, -> { where(enabled: true) }
  scope :by_category, ->(category) { where(category: category) }

  # 設定変更時に全アプリケーション設定を動的に更新
  after_commit :reload_application_settings

  # 設定値を適切な型で取得
  def typed_value
    case setting_type
    when "integer"
      value&.to_i
    when "boolean"
      value == "true"
    when "json", "array"
      value.present? ? JSON.parse(value) : nil
    else
      value
    end
  rescue JSON::ParserError
    nil
  end

  # 設定値を保存前に文字列に変換
  def value=(new_value)
    case setting_type
    when "json", "array"
      super(new_value.is_a?(String) ? new_value : new_value.to_json)
    when "boolean"
      super(new_value.to_s)
    else
      super(new_value.to_s)
    end
  end

  # クラスメソッド: 設定値を取得
  def self.get(key, default = nil)
    setting = find_by(key_name: key, enabled: true)
    setting&.typed_value || default
  end

  # クラスメソッド: 設定値を更新または作成
  def self.set(key, value, options = {})
    setting = find_or_initialize_by(key_name: key)
    setting.value = value
    setting.setting_type = options[:type] || "string"
    setting.category = options[:category] if options[:category].present?
    setting.description = options[:description] if options[:description]
    setting.enabled = options.fetch(:enabled, true)
    setting.save!
    setting
  end

  # クラスメソッド: 設定をカテゴリごとに取得
  def self.by_category_hash(category)
    by_category(category).enabled.pluck(:key_name, :value, :setting_type)
                         .to_h { |key, value, type| [ key, parse_typed_value(value, type) ] }
  end

  # デフォルト設定値を初期化
  def self.initialize_defaults!
    defaults = {
      # CAPTCHA設定
      "captcha.enabled" => {
        value: "false",
        type: "boolean",
        category: "captcha",
        description: "CAPTCHA機能の有効/無効（本番環境では有効を推奨）"
      },
      "captcha.site_key" => {
        value: "",
        type: "string",
        category: "captcha",
        description: "Cloudflare Turnstile Site Key（https://dash.cloudflare.com から取得）"
      },
      "captcha.secret_key" => {
        value: "",
        type: "string",
        category: "captcha",
        description: "Cloudflare Turnstile Secret Key（https://dash.cloudflare.com から取得）"
      },
      "captcha.timeout" => {
        value: "10",
        type: "integer",
        category: "captcha",
        description: "CAPTCHA検証タイムアウト時間（秒）"
      },
      "captcha.verify_url" => {
        value: "https://challenges.cloudflare.com/turnstile/v0/siteverify",
        type: "string",
        category: "captcha",
        description: "Cloudflare Turnstile 検証API URL"
      },

      # レート制限設定
      "rate_limit.enabled" => {
        value: "true",
        type: "boolean",
        category: "rate_limit",
        description: "レート制限機能の有効/無効"
      },
      "rate_limit.api_requests_per_minute" => {
        value: "60",
        type: "integer",
        category: "rate_limit",
        description: "API リクエスト制限（回/分）"
      },
      "rate_limit.web_requests_per_minute" => {
        value: "120",
        type: "integer",
        category: "rate_limit",
        description: "Web リクエスト制限（回/分）"
      },
      "rate_limit.url_creation_per_hour" => {
        value: "100",
        type: "integer",
        category: "rate_limit",
        description: "短縮URL作成制限（回/時）"
      },
      "rate_limit.login_attempts_per_hour" => {
        value: "10",
        type: "integer",
        category: "rate_limit",
        description: "ログイン試行制限（回/時）"
      },

      # メール設定
      "email.adapter" => {
        value: Rails.env.development? ? "letter_opener" : "smtp",
        type: "string",
        category: "email",
        description: "メール送信方法 letter_opener=Letter Opener (開発用) / smtp=SMTP / mailersend=MailerSend"
      },
      "email.from_address" => {
        value: "noreply@yourdomain.com",
        type: "string",
        category: "email",
        description: "メール送信者アドレス（あなたのドメインに変更してください）"
      },

      # SMTP個別設定
      "email.smtp_address" => {
        value: "smtp.gmail.com",
        type: "string",
        category: "email",
        description: "SMTPサーバー（Gmail例: smtp.gmail.com）"
      },
      "email.smtp_port" => {
        value: "587",
        type: "integer",
        category: "email",
        description: "SMTPポート（通常587または25）"
      },
      "email.smtp_user_name" => {
        value: "",
        type: "string",
        category: "email",
        description: "SMTPユーザー名（通常はメールアドレス）"
      },
      "email.smtp_password" => {
        value: "",
        type: "string",
        category: "email",
        description: "SMTPパスワード（Gmailの場合はアプリパスワード）"
      },
      "email.smtp_authentication" => {
        value: "plain",
        type: "string",
        category: "email",
        description: "SMTP認証方式（通常はplain）"
      },
      "email.smtp_enable_starttls_auto" => {
        value: "true",
        type: "boolean",
        category: "email",
        description: "STARTTLS暗号化（推奨: 有効）"
      },

      "email.mailersend_api_key" => {
        value: "",
        type: "string",
        category: "email",
        description: "MailerSend APIキー（https://www.mailersend.com から取得）"
      },

      # パフォーマンス設定
      "performance.cache_ttl" => {
        value: "3600",
        type: "integer",
        category: "performance",
        description: "キャッシュの有効期間（秒）"
      },
      "performance.items_per_page" => {
        value: "20",
        type: "integer",
        category: "performance",
        description: "一覧表示件数"
      },
      "performance.database_timeout" => {
        value: "30",
        type: "integer",
        category: "performance",
        description: "データベース接続タイムアウト（秒）"
      },

      # セキュリティ設定
      "security.password_min_length" => {
        value: "8",
        type: "integer",
        category: "security",
        description: "パスワード最小長"
      },
      "security.session_timeout_hours" => {
        value: "24",
        type: "integer",
        category: "security",
        description: "セッション有効期限（時間）"
      },
      "security.max_login_attempts" => {
        value: "5",
        type: "integer",
        category: "security",
        description: "ログイン失敗回数制限"
      },
      "security.account_lockout_time" => {
        value: "30",
        type: "integer",
        category: "security",
        description: "アカウントロック時間（分）"
      },
      "security.require_strong_password" => {
        value: "false",
        type: "boolean",
        category: "security",
        description: "強固なパスワード要求"
      },

      # システム設定
      "system.site_url" => {
        value: "https://yourdomain.com",
        type: "string",
        category: "system",
        description: "あなたのサイトURL（httpsを推奨）"
      },
      "system.site_name" => {
        value: "My URL Shortener",
        type: "string",
        category: "system",
        description: "サービス名（ブランド名）"
      },
      "system.timezone" => {
        value: "Tokyo",
        type: "string",
        category: "system",
        description: "タイムゾーン"
      },
      "system.maintenance_mode" => {
        value: "false",
        type: "boolean",
        category: "system",
        description: "メンテナンスモード"
      },
      "system.allow_user_registration" => {
        value: "true",
        type: "boolean",
        category: "system",
        description: "新規ユーザー登録"
      },
      "system.log_level" => {
        value: "info",
        type: "string",
        category: "system",
        description: "ログレベル"
      },

      # Shlink API設定
      "shlink.base_url" => {
        value: "",
        type: "string",
        category: "shlink",
        description: "Shlink API ベースURL（例: https://your-shlink.example.com）"
      },
      "shlink.api_key" => {
        value: "",
        type: "string",
        category: "shlink",
        description: "Shlink API認証キー"
      },
      "shlink.timeout" => {
        value: "30",
        type: "integer",
        category: "shlink",
        description: "API接続タイムアウト（秒）"
      },
      "shlink.retry_attempts" => {
        value: "3",
        type: "integer",
        category: "shlink",
        description: "API接続リトライ回数"
      },

      # 法的文書設定
      "legal.terms_of_service" => {
        value: load_legal_template("terms_of_service.md"),
        type: "string",
        category: "legal",
        description: "利用規約（Markdown形式で記載）"
      },
      "legal.privacy_policy" => {
        value: load_legal_template("privacy_policy.md"),
        type: "string",
        category: "legal",
        description: "プライバシーポリシー（Markdown形式で記載）"
      },
      "legal.require_agreement_on_registration" => {
        value: "true",
        type: "boolean",
        category: "legal",
        description: "新規登録時に利用規約・プライバシーポリシーへの同意を必須とする"
      }
    }

    defaults.each do |key, options|
      next if exists?(key_name: key)

      # config gemからデフォルト値を取得
      config_value = get_config_gem_value(key, options[:value])

      set(key, config_value, {
        type: options[:type],
        category: options[:category],
        description: options[:description]
      })
    end
  end

  private

  def self.parse_typed_value(value, type)
    case type
    when "integer"
      value&.to_i
    when "boolean"
      value == "true"
    when "json", "array"
      value.present? ? JSON.parse(value) : nil
    else
      value
    end
  rescue JSON::ParserError
    nil
  end

  # 設定値制約のバリデーション
  def validate_setting_constraints
    return unless value.present?

    case key_name
    # System設定
    when "system.timezone"
      unless ActiveSupport::TimeZone.all.map(&:name).include?(value)
        errors.add(:value, :invalid_timezone)
      end
    when "system.log_level"
      unless %w[debug info warn error fatal].include?(value.downcase)
        errors.add(:value, :invalid_log_level)
      end

    # Performance設定
    when "performance.database_timeout"
      timeout = value.to_i
      unless (1..300).include?(timeout)
        errors.add(:value, :range_database_timeout)
      end
    when "performance.items_per_page"
      items = value.to_i
      unless (1..100).include?(items)
        errors.add(:value, :range_items_per_page)
      end
    when "performance.cache_ttl"
      ttl = value.to_i
      unless (60..86400).include?(ttl)
        errors.add(:value, :range_cache_ttl)
      end

    # Security設定
    when "security.password_min_length"
      length = value.to_i
      unless (6..128).include?(length)
        errors.add(:value, :range_password_length)
      end
    when "security.session_timeout_hours"
      hours = value.to_i
      unless (1..168).include?(hours)
        errors.add(:value, :range_session_timeout)
      end
    when "security.max_login_attempts"
      attempts = value.to_i
      unless (1..20).include?(attempts)
        errors.add(:value, :range_login_attempts)
      end
    when "security.account_lockout_time"
      minutes = value.to_i
      unless (1..1440).include?(minutes)
        errors.add(:value, :range_lockout_time)
      end

    # Rate Limit設定
    when "rate_limit.api_requests_per_minute"
      rate = value.to_i
      unless (1..1000).include?(rate)
        errors.add(:value, :range_api_requests)
      end
    when "rate_limit.web_requests_per_minute"
      rate = value.to_i
      unless (1..1000).include?(rate)
        errors.add(:value, :range_web_requests)
      end
    when "rate_limit.url_creation_per_hour"
      rate = value.to_i
      unless (1..10000).include?(rate)
        errors.add(:value, :range_url_creation)
      end
    when "rate_limit.login_attempts_per_hour"
      rate = value.to_i
      unless (1..100).include?(rate)
        errors.add(:value, :range_login_rate)
      end

    # CAPTCHA設定
    when "captcha.timeout"
      timeout = value.to_i
      unless (5..60).include?(timeout)
        errors.add(:value, :range_captcha_timeout)
      end
    when "captcha.site_key"
      if value.present? && (value.length < 20 || !value.match?(/^[0-9A-Za-z_-]+$/))
        errors.add(:value, :invalid_captcha_key)
      end
    when "captcha.secret_key"
      if value.present? && (value.length < 20 || !value.match?(/^[0-9A-Za-z_-]+$/))
        errors.add(:value, :invalid_captcha_key)
      end

    # Shlink設定
    when "shlink.base_url"
      if value.present?
        begin
          uri = URI.parse(value)
          unless %w[http https].include?(uri.scheme)
            errors.add(:value, :invalid_https_url)
          end
        rescue URI::InvalidURIError
          errors.add(:value, :invalid_url)
        end
      end
    when "shlink.timeout"
      timeout = value.to_i
      unless (5..300).include?(timeout)
        errors.add(:value, :range_shlink_timeout)
      end
    when "shlink.retry_attempts"
      attempts = value.to_i
      unless (0..10).include?(attempts)
        errors.add(:value, :range_retry_attempts)
      end

    # Email設定
    when "email.adapter"
      unless %w[letter_opener smtp mailersend].include?(value.downcase)
        errors.add(:value, :invalid_email_adapter)
      end
    when "email.from_address"
      unless value.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
        errors.add(:value, :invalid_email_address)
      end
    when "email.smtp_port"
      port = value.to_i
      unless (1..65535).include?(port)
        errors.add(:value, :range_smtp_port)
      end
    end
  end

  # config gemから設定値を取得
  def self.get_config_gem_value(key, fallback_value)
    # キー名をconfig gem形式に変換
    config_keys = key.split(".")

    begin
      current = Settings
      config_keys.each do |k|
        return fallback_value unless current.respond_to?(k)
        current = current.send(k)
      end

      # 値が存在すれば使用、なければfallback
      current.present? ? current.to_s : fallback_value
    rescue => e
      Rails.logger.debug "Config gem access error for key '#{key}': #{e.message}"
      fallback_value
    end
  end

  # 法的文書テンプレートを読み込み
  def self.load_legal_template(filename)
    template_path = Rails.root.join("config", "legal_templates", filename)
    if File.exist?(template_path)
      File.read(template_path).strip
    else
      # テンプレートファイルが存在しない場合のフォールバック
      case filename
      when "terms_of_service.md"
        "# 利用規約\n\n当サービスの利用規約を記載してください。\n\n## 1. サービスの利用について\n\n..."
      when "privacy_policy.md"
        "# プライバシーポリシー\n\n当サービスのプライバシーポリシーを記載してください。\n\n## 1. 収集する情報について\n\n..."
      else
        "法的文書テンプレートが見つかりません。"
      end
    end
  rescue => e
    Rails.logger.error "Legal template loading error for '#{filename}': #{e.message}"
    "テンプレート読み込みエラー: #{e.message}"
  end

  private

  # 設定変更時に全アプリケーション設定を動的に更新
  def reload_application_settings
    # バックグラウンドで設定を更新（パフォーマンスを考慮）
    ApplicationConfig.reload_all_settings!
  end
end
