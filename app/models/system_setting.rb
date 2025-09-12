class SystemSetting < ApplicationRecord
  validates :key_name, presence: true, uniqueness: true
  validates :setting_type, presence: true, inclusion: { in: %w[string integer boolean json array] }

  # 設定カテゴリの定数
  CATEGORIES = {
    captcha: "captcha",
    rate_limit: "rate_limit",
    email: "email",
    performance: "performance",
    security: "security",
    system: "system"
  }.freeze

  validates :category, inclusion: { in: CATEGORIES.values }, allow_blank: true

  scope :enabled, -> { where(enabled: true) }
  scope :by_category, ->(category) { where(category: category) }

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
    setting.category = options[:category]
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
        description: "CAPTCHA機能の有効/無効"
      },
      "captcha.site_key" => {
        value: "",
        type: "string",
        category: "captcha",
        description: "Cloudflare Turnstile Site Key"
      },
      "captcha.secret_key" => {
        value: "",
        type: "string",
        category: "captcha",
        description: "Cloudflare Turnstile Secret Key"
      },

      # レート制限設定
      "rate_limit.enabled" => {
        value: "true",
        type: "boolean",
        category: "rate_limit",
        description: "レート制限機能の有効/無効"
      },
      "rate_limit.requests_per_minute" => {
        value: "60",
        type: "integer",
        category: "rate_limit",
        description: "1分間あたりの最大リクエスト数"
      },
      "rate_limit.burst_limit" => {
        value: "100",
        type: "integer",
        category: "rate_limit",
        description: "バースト制限（一時的なリクエスト急増許容数）"
      },

      # メール設定
      "email.adapter" => {
        value: "smtp",
        type: "string",
        category: "email",
        description: "メール送信アダプター（smtp, mailersend）"
      },
      "email.from_address" => {
        value: "noreply@example.com",
        type: "string",
        category: "email",
        description: "送信元メールアドレス"
      },
      "email.smtp_settings" => {
        value: "{\"address\":\"smtp.gmail.com\",\"port\":587,\"authentication\":\"plain\",\"enable_starttls_auto\":true}",
        type: "json",
        category: "email",
        description: "SMTP設定（JSON形式）"
      },
      "email.mailersend_api_key" => {
        value: "",
        type: "string",
        category: "email",
        description: "MailerSend APIキー"
      },

      # パフォーマンス設定
      "performance.cache_ttl" => {
        value: "3600",
        type: "integer",
        category: "performance",
        description: "キャッシュの有効期間（秒）"
      },
      "performance.page_size" => {
        value: "20",
        type: "integer",
        category: "performance",
        description: "ページネーションのページサイズ"
      },
      "performance.max_short_urls_per_user" => {
        value: "1000",
        type: "integer",
        category: "performance",
        description: "ユーザー1人あたりの最大短縮URL数"
      },

      # セキュリティ設定
      "security.require_2fa_for_admin" => {
        value: "true",
        type: "boolean",
        category: "security",
        description: "管理者に2FA認証を必須とする"
      },
      "security.session_timeout" => {
        value: "7200",
        type: "integer",
        category: "security",
        description: "セッション有効期間（秒）"
      },
      "security.password_min_length" => {
        value: "8",
        type: "integer",
        category: "security",
        description: "パスワード最小長"
      },

      # システム設定
      "system.site_name" => {
        value: "Shlink-UI-Rails",
        type: "string",
        category: "system",
        description: "サイト名"
      },
      "system.site_url" => {
        value: "http://localhost:3000",
        type: "string",
        category: "system",
        description: "サイトURL"
      },
      "system.maintenance_mode" => {
        value: "false",
        type: "boolean",
        category: "system",
        description: "メンテナンスモード"
      },
      "system.default_short_code_length" => {
        value: "5",
        type: "integer",
        category: "system",
        description: "デフォルト短縮コード長"
      },
      "system.allowed_domains" => {
        value: "[]",
        type: "array",
        category: "system",
        description: "許可ドメイン一覧（空の場合は全て許可）"
      }
    }

    defaults.each do |key, options|
      next if exists?(key_name: key)

      set(key, options[:value], {
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
end
