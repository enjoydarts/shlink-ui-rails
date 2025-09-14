require 'rails_helper'

RSpec.describe SystemSettingsHelper, type: :helper do
  before do
    allow(SystemSetting).to receive(:get)
    allow(Rails.cache).to receive(:fetch).and_yield
    allow(Rails.cache).to receive(:delete_matched)
    logger_double = double('Logger')
    allow(logger_double).to receive(:level).and_return(1)
    allow(logger_double).to receive(:level=)
    allow(logger_double).to receive(:info)
    allow(logger_double).to receive(:warn)
    allow(logger_double).to receive(:error)
    allow(Rails).to receive(:logger).and_return(logger_double)
  end

  describe '#system_setting' do
    it 'キャッシュを使用してSystemSettingから値を取得すること' do
      allow(SystemSetting).to receive(:get).with('performance.cache_ttl', 3600).and_return(3600)
      allow(SystemSetting).to receive(:get).with('test.key', 'default').and_return('cached_value')

      result = helper.system_setting('test.key', 'default')

      expect(Rails.cache).to have_received(:fetch).with('system_setting:test.key', expires_in: anything)
      expect(result).to eq('cached_value')
    end

    it 'cache_ttlを動的に取得すること' do
      allow(SystemSetting).to receive(:get).with('performance.cache_ttl', 3600).and_return(7200)
      allow(SystemSetting).to receive(:get).with('test.key', nil).and_return('value')

      helper.system_setting('test.key')

      expect(SystemSetting).to have_received(:get).with('performance.cache_ttl', 3600)
    end
  end

  describe '#site_name' do
    it 'デフォルト値でsystem.site_nameを取得すること' do
      expect(helper).to receive(:system_setting).with('system.site_name', 'Shlink-UI-Rails')

      helper.site_name
    end
  end

  describe '#site_url' do
    before do
      allow(request).to receive(:base_url).and_return('http://test.local:3000')
    end

    it 'system.site_urlを取得し、フォールバックとしてrequest.base_urlを使用すること' do
      expect(helper).to receive(:system_setting).with('system.site_url', 'http://test.local:3000')

      helper.site_url
    end
  end

  describe '#maintenance_mode?' do
    it 'system.maintenance_modeをfalseデフォルトで取得すること' do
      expect(helper).to receive(:system_setting).with('system.maintenance_mode', false)

      helper.maintenance_mode?
    end
  end

  describe '#captcha_enabled?' do
    it 'captcha.enabledをfalseデフォルトで取得すること' do
      expect(helper).to receive(:system_setting).with('captcha.enabled', false)

      helper.captcha_enabled?
    end
  end

  describe '#rate_limit_enabled?' do
    it 'rate_limit.enabledをtrueデフォルトで取得すること' do
      expect(helper).to receive(:system_setting).with('rate_limit.enabled', true)

      helper.rate_limit_enabled?
    end
  end

  describe '#page_size' do
    it 'performance.page_sizeを20デフォルトで取得すること' do
      expect(helper).to receive(:system_setting).with('performance.page_size', 20)

      helper.page_size
    end
  end

  describe '#password_min_length' do
    it 'security.password_min_lengthを8デフォルトで取得すること' do
      expect(helper).to receive(:system_setting).with('security.password_min_length', 8)

      helper.password_min_length
    end
  end

  describe '#require_2fa_for_admin?' do
    it 'security.require_2fa_for_adminをtrueデフォルトで取得すること' do
      expect(helper).to receive(:system_setting).with('security.require_2fa_for_admin', true)

      helper.require_2fa_for_admin?
    end
  end

  describe '#max_short_urls_per_user' do
    it 'performance.max_short_urls_per_userを1000デフォルトで取得すること' do
      expect(helper).to receive(:system_setting).with('performance.max_short_urls_per_user', 1000)

      helper.max_short_urls_per_user
    end
  end

  describe '#default_short_code_length' do
    it 'system.default_short_code_lengthを5デフォルトで取得すること' do
      expect(helper).to receive(:system_setting).with('system.default_short_code_length', 5)

      helper.default_short_code_length
    end
  end

  describe '#allowed_domains' do
    it 'system.allowed_domainsを空配列デフォルトで取得すること' do
      expect(helper).to receive(:system_setting).with('system.allowed_domains', [])

      helper.allowed_domains
    end
  end

  describe '#smtp_settings_hash' do
    before do
      allow(helper).to receive(:system_setting).with('email.smtp_address', 'smtp.gmail.com').and_return('smtp.test.com')
      allow(helper).to receive(:system_setting).with('email.smtp_port', 587).and_return(25)
      allow(helper).to receive(:system_setting).with('email.smtp_user_name', '').and_return('user@test.com')
      allow(helper).to receive(:system_setting).with('email.smtp_password', '').and_return('password')
      allow(helper).to receive(:system_setting).with('email.smtp_authentication', 'plain').and_return('login')
      allow(helper).to receive(:system_setting).with('email.smtp_enable_starttls_auto', true).and_return(false)
    end

    it 'SMTP設定のハッシュを正しく構築すること' do
      result = helper.smtp_settings_hash

      expect(result).to eq({
        address: 'smtp.test.com',
        port: 25,
        user_name: 'user@test.com',
        password: 'password',
        authentication: 'login',
        enable_starttls_auto: false
      })
    end

    it '各設定項目を正しいデフォルト値で取得すること' do
      helper.smtp_settings_hash

      expect(helper).to have_received(:system_setting).with('email.smtp_address', 'smtp.gmail.com')
      expect(helper).to have_received(:system_setting).with('email.smtp_port', 587)
      expect(helper).to have_received(:system_setting).with('email.smtp_user_name', '')
      expect(helper).to have_received(:system_setting).with('email.smtp_password', '')
      expect(helper).to have_received(:system_setting).with('email.smtp_authentication', 'plain')
      expect(helper).to have_received(:system_setting).with('email.smtp_enable_starttls_auto', true)
    end
  end

  describe '#email_from_address' do
    it 'email.from_addressをデフォルト値で取得すること' do
      expect(helper).to receive(:system_setting).with('email.from_address', 'noreply@example.com')

      helper.email_from_address
    end
  end

  describe '#email_adapter' do
    it 'email.adapterをsmtpデフォルトで取得すること' do
      expect(helper).to receive(:system_setting).with('email.adapter', 'smtp')

      helper.email_adapter
    end
  end

  describe '#refresh_system_settings!' do
    let(:connection_pool) { double('ConnectionPool') }
    let(:connection) { double('Connection') }

    before do
      allow(ActiveRecord::Base).to receive(:connection_pool).and_return(connection_pool)
      allow(connection_pool).to receive(:with_connection).and_yield(connection)
      allow(connection).to receive(:execute)
      allow(Time).to receive(:zone=)
    end

    it 'システム設定のキャッシュをクリアすること' do
      helper.refresh_system_settings!

      expect(Rails.cache).to have_received(:delete_matched).with('system_setting:*')
    end

    it 'タイムゾーン設定を更新すること' do
      allow(SystemSetting).to receive(:get).with('system.timezone', 'Asia/Tokyo').and_return('UTC')

      helper.refresh_system_settings!

      expect(Time).to have_received(:zone=).with('UTC')
    end

    it 'ログレベルを更新すること' do
      allow(SystemSetting).to receive(:get).with('system.log_level', 'info').and_return('debug')
      allow(SystemSetting).to receive(:get).with('system.timezone', 'Asia/Tokyo').and_return('UTC')
      logger = double('Logger')
      allow(logger).to receive(:level=)
      allow(logger).to receive(:level).and_return(Logger::DEBUG)
      allow(logger).to receive(:info)
      allow(logger).to receive(:error)  # エラー処理用
      allow(Rails).to receive(:logger).and_return(logger)

      helper.refresh_system_settings!

      expect(logger).to have_received(:level=).with(Logger::DEBUG)
    end

    it 'データベースタイムアウト設定を更新すること' do
      allow(SystemSetting).to receive(:get).with('performance.database_timeout', 30).and_return(60)
      allow(SystemSetting).to receive(:get).with('system.timezone', 'Asia/Tokyo').and_return('UTC')
      allow(SystemSetting).to receive(:get).with('system.log_level', 'info').and_return('info')

      helper.refresh_system_settings!

      expect(connection).to have_received(:execute).with('SET SESSION wait_timeout = 60')
      expect(connection).to have_received(:execute).with('SET SESSION interactive_timeout = 60')
    end

    context 'Deviseが定義されている場合' do
      let(:devise_class) { double('Devise') }

      before do
        stub_const('Devise', devise_class)
        allow(devise_class).to receive(:maximum_attempts=)
        allow(devise_class).to receive(:unlock_in=)
        allow(devise_class).to receive(:password_length=)
        allow(devise_class).to receive(:timeout_in=)

        allow(SystemSetting).to receive(:get).with('security.max_login_attempts', 5).and_return(3)
        allow(SystemSetting).to receive(:get).with('security.account_lockout_time', 30).and_return(15)
        allow(SystemSetting).to receive(:get).with('security.password_min_length', 8).and_return(10)
        allow(SystemSetting).to receive(:get).with('security.session_timeout_hours', 24).and_return(12)
        allow(SystemSetting).to receive(:get).with('system.timezone', 'Asia/Tokyo').and_return('UTC')
        allow(SystemSetting).to receive(:get).with('system.log_level', 'info').and_return('info')
      end

      it 'Devise設定を更新すること' do
        helper.refresh_system_settings!

        expect(devise_class).to have_received(:maximum_attempts=).with(3)
        expect(devise_class).to have_received(:unlock_in=).with(15.minutes)
        expect(devise_class).to have_received(:password_length=).with(10..128)
        expect(devise_class).to have_received(:timeout_in=).with(12.hours)
      end
    end

    context 'ActionMailer設定の更新' do
      let(:rails_app_config) { double('Rails::Application::Configuration') }
      let(:action_mailer_config) { double('ActionMailer::Configuration') }

      before do
        allow(Rails.application).to receive(:config).and_return(rails_app_config)
        allow(rails_app_config).to receive(:action_mailer).and_return(action_mailer_config)
        action_view_config = double('ActionView::Configuration')
        allow(action_view_config).to receive(:cache_template_loading).and_return(true)
        allow(action_view_config).to receive(:each)  # each メソッドのスタブを追加
        allow(rails_app_config).to receive(:action_view).and_return(action_view_config)
        allow(rails_app_config).to receive(:root).and_return('/app')
        allow(action_mailer_config).to receive(:delivery_method=)
        allow(action_mailer_config).to receive(:smtp_settings=)
        allow(action_mailer_config).to receive(:default_options=)
        allow(action_mailer_config).to receive(:default_url_options=)

        allow(helper).to receive(:smtp_settings_hash).and_return({ address: 'smtp.test.com' })
        allow(helper).to receive(:email_from_address).and_return('test@example.com')
        allow(helper).to receive(:system_setting).with('system.site_url', anything).and_return('https://test.com')
        allow(request).to receive(:base_url).and_return('http://localhost:3000')

        # 基本的なSystemSetting設定を追加
        allow(SystemSetting).to receive(:get).with('system.timezone', 'Asia/Tokyo').and_return('UTC')
        allow(SystemSetting).to receive(:get).with('system.log_level', 'info').and_return('info')
      end

      context 'メールアダプターがmailersendの場合' do
        before do
          allow(SystemSetting).to receive(:get).with('email.adapter', 'smtp').and_return('mailersend')
          allow(SystemSetting).to receive(:get).with('email.mailersend_api_key', '').and_return('test-api-key')
        end

        it 'MailerSendを配信方法として設定すること' do
          helper.refresh_system_settings!

          expect(action_mailer_config).to have_received(:delivery_method=).with(:mailersend)
        end
      end

      context 'メールアダプターがSMTPの場合' do
        before do
          allow(SystemSetting).to receive(:get).with('email.adapter', 'smtp').and_return('smtp')
        end

        it 'SMTPを配信方法として設定すること' do
          helper.refresh_system_settings!

          expect(action_mailer_config).to have_received(:delivery_method=).with(:smtp)
          expect(action_mailer_config).to have_received(:smtp_settings=).with({ address: 'smtp.test.com' })
        end
      end

      it 'デフォルト送信者とURL設定を更新すること' do
        # email.adapterのデフォルト設定を追加
        allow(SystemSetting).to receive(:get).with('email.adapter', 'smtp').and_return('smtp')

        helper.refresh_system_settings!

        expect(action_mailer_config).to have_received(:default_options=).with({ from: 'test@example.com' })
        expect(action_mailer_config).to have_received(:default_url_options=).with({
          host: 'test.com',
          port: 443,
          protocol: 'https'
        })
      end
    end

    context 'エラーが発生した場合' do
      before do
        allow(SystemSetting).to receive(:get).and_raise(StandardError.new('Database error'))
      end

      it 'エラーログを出力し、例外を発生させないこと' do
        expect { helper.refresh_system_settings! }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with(/システム設定の再読み込み中にエラーが発生/)
      end
    end
  end
end
