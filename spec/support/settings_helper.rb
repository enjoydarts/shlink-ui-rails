module SettingsHelper
  def mock_smtp_settings
    allow(Settings).to receive(:mail_delivery_method).and_return('smtp')
    allow(Settings).to receive(:mailer).and_return(
      OpenStruct.new(
        address: 'smtp.example.com',
        domain: 'example.com',
        user_name: 'user@example.com',
        password: 'password123',
        from: 'smtp@example.com'
      )
    )
  end

  def mock_mailersend_settings
    allow(Settings).to receive(:mail_delivery_method).and_return('mailersend')
    allow(Settings).to receive(:mailersend).and_return(
      OpenStruct.new(
        api_key: 'test-api-key',
        from_email: 'test@example.com',
        from_name: 'Test App'
      )
    )
  end

  def mock_invalid_settings
    allow(Settings).to receive(:mail_delivery_method).and_return('invalid')
  end

  def mock_settings_error
    allow(Settings).to receive(:mail_delivery_method).and_raise(StandardError.new('設定エラー'))
  end

  def mock_incomplete_smtp_settings
    allow(Settings).to receive(:mail_delivery_method).and_return('smtp')
    allow(Settings).to receive(:mailer).and_return(
      OpenStruct.new(
        address: 'smtp.example.com',
        domain: '',  # 空の値
        user_name: 'user@example.com',
        password: 'password123',
        from: 'smtp@example.com'
      )
    )
  end

  def mock_incomplete_mailersend_settings
    allow(Settings).to receive(:mail_delivery_method).and_return('mailersend')
    allow(Settings).to receive(:mailersend).and_return(
      OpenStruct.new(
        api_key: '',  # 空のAPIキー
        from_email: 'test@example.com',
        from_name: 'Test App'
      )
    )
  end
end

RSpec.configure do |config|
  config.include SettingsHelper
end
