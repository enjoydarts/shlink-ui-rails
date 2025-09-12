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
        description: "Turnstile Site Key"
      },
      "captcha.secret_key" => {
        value: "",
        type: "string",
        category: "captcha",
        description: "Turnstile Secret Key"
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

      # メール設定
      "email.adapter" => {
        value: "smtp",
        type: "string",
        category: "email",
        description: "メール送信アダプター（smtp, mailersend）"
      },
      "email.smtp_settings" => {
        value: "{}",
        type: "json",
        category: "email",
        description: "SMTP設定（JSON形式）"
      },

      # パフォーマンス設定
      "performance.cache_ttl" => {
        value: "3600",
        type: "integer",
        category: "performance",
        description: "キャッシュの有効期間（秒）"
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
