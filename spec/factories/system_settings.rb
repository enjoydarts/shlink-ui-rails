FactoryBot.define do
  factory :system_setting do
    sequence(:key_name) { |n| "test_setting_#{n}" }
    value { "test_value" }
    setting_type { "string" }
    category { "system" }
    description { "テスト用設定" }
    enabled { true }

    trait :boolean_setting do
      setting_type { "boolean" }
      value { "true" }
    end

    trait :integer_setting do
      setting_type { "integer" }
      value { "100" }
    end

    trait :json_setting do
      setting_type { "json" }
      value { '{"key": "value"}' }
    end

    trait :disabled do
      enabled { false }
    end

    # 具体的な設定用のファクトリー
    factory :captcha_enabled_setting do
      key_name { "captcha.enabled" }
      value { "true" }
      setting_type { "boolean" }
      category { "captcha" }
      description { "CAPTCHA機能の有効/無効" }
    end

    factory :rate_limit_setting do
      key_name { "rate_limit.requests_per_minute" }
      value { "60" }
      setting_type { "integer" }
      category { "rate_limit" }
      description { "1分間あたりの最大リクエスト数" }
    end
  end
end
