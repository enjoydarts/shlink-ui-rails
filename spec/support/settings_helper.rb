module SettingsHelper
  def reset_all_mocks
    # 全てのモックをリセット
    RSpec::Mocks.teardown
    RSpec::Mocks.setup
  end

  def disable_strong_password_requirement
    # パスワード強度要求を無効化
    allow(SystemSetting).to receive(:get).with("security.require_strong_password", true).and_return(false)

    # その他よく使われるSystemSettingのデフォルト値をモック
    allow(SystemSetting).to receive(:get).with("performance.cache_ttl", 3600).and_return(3600)
    allow(SystemSetting).to receive(:get).with("maintenance.enabled", false).and_return(false)
    allow(SystemSetting).to receive(:get).with("performance.items_per_page", anything).and_return(20)

    # Fallback for any other SystemSetting.get calls
    allow(SystemSetting).to receive(:get).and_call_original
  end
  def mock_smtp_settings
    allow(SystemSetting).to receive(:get).with("email.adapter", "smtp").and_return('smtp')
    # SMTPアダプタ用の設定をモック（実際のキー名を使用）
    allow(SystemSetting).to receive(:get).with("email.smtp_address", "").and_return('smtp.example.com')
    allow(SystemSetting).to receive(:get).with("email.smtp_user_name", "").and_return('user@example.com')
    allow(SystemSetting).to receive(:get).with("email.smtp_password", "").and_return('password123')
    allow(SystemSetting).to receive(:get).with("email.from", anything).and_return('smtp@example.com')
  end

  def mock_mailersend_settings
    allow(SystemSetting).to receive(:get).with("email.adapter", "smtp").and_return('mailersend')
    # MailerSendアダプタ用の設定をモック（実際のキー名を使用）
    allow(SystemSetting).to receive(:get).with("email.mailersend_api_key", "").and_return('test-api-key')
    allow(SystemSetting).to receive(:get).with("email.from_address", "noreply@example.com").and_return('test@example.com')
    allow(SystemSetting).to receive(:get).with("system.site_name", "Shlink-UI-Rails").and_return('Test App')
  end

  def mock_invalid_settings
    allow(SystemSetting).to receive(:get).with("email.adapter", "smtp").and_return('invalid')
    # フォールバック先SMTPの設定も追加
    allow(SystemSetting).to receive(:get).with("email.smtp_address", "").and_return('smtp.example.com')
    allow(SystemSetting).to receive(:get).with("email.smtp_user_name", "").and_return('user@example.com')
    allow(SystemSetting).to receive(:get).with("email.smtp_password", "").and_return('password123')
    allow(SystemSetting).to receive(:get).with("email.from", anything).and_return('smtp@example.com')
  end

  def mock_settings_error
    allow(SystemSetting).to receive(:get).with("email.adapter", "smtp").and_raise(StandardError.new('設定エラー'))
    # エラー後のフォールバック用SMTP設定
    allow(SystemSetting).to receive(:get).with("email.smtp_address", "").and_return('smtp.example.com')
    allow(SystemSetting).to receive(:get).with("email.smtp_user_name", "").and_return('user@example.com')
    allow(SystemSetting).to receive(:get).with("email.smtp_password", "").and_return('password123')
    allow(SystemSetting).to receive(:get).with("email.from", anything).and_return('smtp@example.com')
  end

  def mock_incomplete_smtp_settings
    allow(SystemSetting).to receive(:get).with("email.adapter", "smtp").and_return('smtp')
    # SMTPアダプタ用の不完全設定をモック（必要な設定が空）
    allow(SystemSetting).to receive(:get).with("email.smtp_address", "").and_return('')
    allow(SystemSetting).to receive(:get).with("email.smtp_user_name", "").and_return('user@example.com')
    allow(SystemSetting).to receive(:get).with("email.smtp_password", "").and_return('password123')
    allow(SystemSetting).to receive(:get).with("email.from", anything).and_return('smtp@example.com')
  end

  def mock_incomplete_mailersend_settings
    allow(SystemSetting).to receive(:get).with("email.adapter", "smtp").and_return('mailersend')
    # MailerSendアダプタ用の不完全設定をモック（APIキーが空）
    allow(SystemSetting).to receive(:get).with("email.mailersend_api_key", "").and_return('')
    allow(SystemSetting).to receive(:get).with("email.from_address", "noreply@example.com").and_return('test@example.com')
    allow(SystemSetting).to receive(:get).with("system.site_name", "Shlink-UI-Rails").and_return('Test App')
  end
end

RSpec.configure do |config|
  config.include SettingsHelper
end
