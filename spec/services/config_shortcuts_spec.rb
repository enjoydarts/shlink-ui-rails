require 'rails_helper'

RSpec.describe ConfigShortcuts do
  let(:test_class) { Class.new { include ConfigShortcuts }.new }

  before do
    allow(ApplicationConfig).to receive(:enabled?).and_return(false)
    allow(ApplicationConfig).to receive(:string).and_return('')
    allow(ApplicationConfig).to receive(:number).and_return(0)
    allow(ApplicationConfig).to receive(:category).and_return({})

    # Settings関連のモック
    if defined?(Settings)
      allow(Settings).to receive_message_chain(:shlink, :base_url).and_return('https://test.example.com')
      allow(Settings).to receive_message_chain(:shlink, :api_key).and_return('test-api-key')
      allow(Settings).to receive_message_chain(:shlink, :timeout).and_return(30)
      allow(Settings).to receive_message_chain(:shlink, :retry_attempts).and_return(3)
      allow(Settings).to receive_message_chain(:redis, :url).and_return('redis://test:6379/0')
      allow(Settings).to receive_message_chain(:redis, :timeout).and_return(5)
      allow(Settings).to receive_message_chain(:redis, :pool_size).and_return(5)
      allow(Settings).to receive_message_chain(:webauthn, :rp_name).and_return('Test App')
      allow(Settings).to receive_message_chain(:webauthn, :rp_id).and_return('test.local')
      allow(Settings).to receive_message_chain(:webauthn, :origin).and_return('http://test.local:3000')
      allow(Settings).to receive_message_chain(:app, :pagination, :per_page).and_return(20)
      allow(Settings).to receive_message_chain(:app, :pagination, :max_per_page).and_return(100)
      allow(Settings).to receive_message_chain(:app, :short_url, :max_tags).and_return(10)
      allow(Settings).to receive_message_chain(:app, :short_url, :max_tag_length).and_return(20)
    end
  end

  describe 'CAPTCHA設定' do
    describe '#captcha_enabled?' do
      it 'ApplicationConfig.enabled?を正しい引数で呼び出すこと' do
        test_class.captcha_enabled?

        expect(ApplicationConfig).to have_received(:enabled?).with('captcha.enabled', false)
      end
    end

    describe '#captcha_site_key' do
      it 'ApplicationConfig.stringを正しい引数で呼び出すこと' do
        test_class.captcha_site_key

        expect(ApplicationConfig).to have_received(:string).with('captcha.site_key')
      end
    end

    describe '#captcha_secret_key' do
      it 'ApplicationConfig.stringを正しい引数で呼び出すこと' do
        test_class.captcha_secret_key

        expect(ApplicationConfig).to have_received(:string).with('captcha.secret_key')
      end
    end

    describe '#captcha_timeout' do
      it 'ApplicationConfig.numberを正しい引数で呼び出すこと' do
        test_class.captcha_timeout

        expect(ApplicationConfig).to have_received(:number).with('captcha.timeout', 10)
      end
    end
  end

  describe 'Rate Limiting設定' do
    describe '#rate_limit_enabled?' do
      it 'ApplicationConfig.enabled?を正しい引数で呼び出すこと' do
        test_class.rate_limit_enabled?

        expect(ApplicationConfig).to have_received(:enabled?).with('rate_limit.enabled', true)
      end
    end

    describe '#login_rate_limit' do
      it 'ApplicationConfig.numberを正しい引数で呼び出すこと' do
        test_class.login_rate_limit

        expect(ApplicationConfig).to have_received(:number).with('rate_limit.login.requests_per_hour', 10)
      end
    end

    describe '#registration_rate_limit' do
      it 'ApplicationConfig.numberを正しい引数で呼び出すこと' do
        test_class.registration_rate_limit

        expect(ApplicationConfig).to have_received(:number).with('rate_limit.registration.requests_per_hour', 5)
      end
    end

    describe '#url_creation_rate_limit' do
      it 'ApplicationConfig.numberを正しい引数で呼び出すこと' do
        test_class.url_creation_rate_limit

        expect(ApplicationConfig).to have_received(:number).with('rate_limit.url_creation.requests_per_minute', 10)
      end
    end
  end

  describe 'Email設定' do
    describe '#email_adapter' do
      it 'ApplicationConfig.stringを正しい引数で呼び出すこと' do
        test_class.email_adapter

        expect(ApplicationConfig).to have_received(:string).with('email.adapter', 'smtp')
      end
    end

    describe '#email_from_address' do
      it 'ApplicationConfig.stringを正しい引数で呼び出すこと' do
        test_class.email_from_address

        expect(ApplicationConfig).to have_received(:string).with('email.from_address')
      end
    end

    describe '#smtp_settings' do
      it 'SMTP設定のハッシュを返すこと' do
        allow(ApplicationConfig).to receive(:string).with('email.smtp_address').and_return('smtp.test.com')
        allow(ApplicationConfig).to receive(:number).with('email.smtp_port', 587).and_return(587)
        allow(ApplicationConfig).to receive(:string).with('email.smtp_user_name').and_return('user')
        allow(ApplicationConfig).to receive(:string).with('email.smtp_password').and_return('pass')
        allow(ApplicationConfig).to receive(:string).with('email.smtp_authentication', 'plain').and_return('plain')
        allow(ApplicationConfig).to receive(:enabled?).with('email.smtp_enable_starttls_auto', true).and_return(true)

        result = test_class.smtp_settings

        expect(result).to eq({
          address: 'smtp.test.com',
          port: 587,
          user_name: 'user',
          password: 'pass',
          authentication: 'plain',
          enable_starttls_auto: true
        })
      end
    end

    describe '#mailersend_api_key' do
      it 'ApplicationConfig.stringを正しい引数で呼び出すこと' do
        test_class.mailersend_api_key

        expect(ApplicationConfig).to have_received(:string).with('email.mailersend_api_key')
      end
    end
  end

  describe 'Shlink API設定' do
    describe '#shlink_base_url' do
      it 'ApplicationConfig.stringを正しい引数で呼び出すこと' do
        test_class.shlink_base_url

        if defined?(Settings)
          expect(ApplicationConfig).to have_received(:string).with('shlink.base_url', 'https://test.example.com')
        else
          expect(ApplicationConfig).to have_received(:string).with('shlink.base_url', nil)
        end
      end
    end

    describe '#shlink_api_key' do
      it 'ApplicationConfig.stringを正しい引数で呼び出すこと' do
        test_class.shlink_api_key

        if defined?(Settings)
          expect(ApplicationConfig).to have_received(:string).with('shlink.api_key', 'test-api-key')
        else
          expect(ApplicationConfig).to have_received(:string).with('shlink.api_key', nil)
        end
      end
    end

    describe '#shlink_timeout' do
      it 'ApplicationConfig.numberを正しい引数で呼び出すこと' do
        test_class.shlink_timeout

        expected_default = defined?(Settings) ? 30 : 30
        expect(ApplicationConfig).to have_received(:number).with('shlink.timeout', expected_default)
      end
    end

    describe '#shlink_retry_attempts' do
      it 'ApplicationConfig.numberを正しい引数で呼び出すこと' do
        test_class.shlink_retry_attempts

        expected_default = defined?(Settings) ? 3 : 3
        expect(ApplicationConfig).to have_received(:number).with('shlink.retry_attempts', expected_default)
      end
    end
  end

  describe 'Performance設定' do
    describe '#performance_cache_ttl' do
      it 'ApplicationConfig.numberを正しい引数で呼び出すこと' do
        test_class.performance_cache_ttl

        expect(ApplicationConfig).to have_received(:number).with('performance.cache_ttl', 300)
      end
    end

    describe '#performance_database_pool_size' do
      it 'ApplicationConfig.numberを正しい引数で呼び出すこと' do
        test_class.performance_database_pool_size

        expect(ApplicationConfig).to have_received(:number).with('performance.database_pool_size', 5)
      end
    end

    describe '#performance_background_job_threads' do
      it 'ApplicationConfig.numberを正しい引数で呼び出すこと' do
        test_class.performance_background_job_threads

        expect(ApplicationConfig).to have_received(:number).with('performance.background_job_threads', 2)
      end
    end
  end

  describe 'Security設定' do
    describe '#security_require_2fa?' do
      it 'ApplicationConfig.enabled?を正しい引数で呼び出すこと' do
        test_class.security_require_2fa?

        expect(ApplicationConfig).to have_received(:enabled?).with('security.require_2fa', false)
      end
    end

    describe '#security_session_timeout' do
      it 'ApplicationConfig.numberを正しい引数で呼び出すこと' do
        test_class.security_session_timeout

        expect(ApplicationConfig).to have_received(:number).with('security.session_timeout', 7200)
      end
    end

    describe '#security_password_complexity_enabled?' do
      it 'ApplicationConfig.enabled?を正しい引数で呼び出すこと' do
        test_class.security_password_complexity_enabled?

        expect(ApplicationConfig).to have_received(:enabled?).with('security.password_complexity', false)
      end
    end
  end

  describe 'System設定' do
    describe '#system_timezone' do
      it 'ApplicationConfig.stringを正しい引数で呼び出すこと' do
        test_class.system_timezone

        expect(ApplicationConfig).to have_received(:string).with('system.timezone', 'Asia/Tokyo')
      end
    end

    describe '#system_log_level' do
      it 'ApplicationConfig.stringを正しい引数で呼び出すこと' do
        test_class.system_log_level

        expect(ApplicationConfig).to have_received(:string).with('system.log_level', 'info')
      end
    end

    describe '#system_maintenance_mode?' do
      it 'ApplicationConfig.enabled?を正しい引数で呼び出すこと' do
        test_class.system_maintenance_mode?

        expect(ApplicationConfig).to have_received(:enabled?).with('system.maintenance_mode', false)
      end
    end
  end

  describe 'Redis設定' do
    describe '#redis_url' do
      it 'ApplicationConfig.stringを正しい引数で呼び出すこと' do
        test_class.redis_url

        if defined?(Settings)
          expect(ApplicationConfig).to have_received(:string).with('redis.url', 'redis://test:6379/0')
        else
          expect(ApplicationConfig).to have_received(:string).with('redis.url', 'redis://redis:6379/0')
        end
      end
    end

    describe '#redis_timeout' do
      it 'ApplicationConfig.numberを正しい引数で呼び出すこと' do
        test_class.redis_timeout

        expected_default = defined?(Settings) ? 5 : 5
        expect(ApplicationConfig).to have_received(:number).with('redis.timeout', expected_default)
      end
    end

    describe '#redis_pool_size' do
      it 'ApplicationConfig.numberを正しい引数で呼び出すこと' do
        test_class.redis_pool_size

        expected_default = defined?(Settings) ? 5 : 5
        expect(ApplicationConfig).to have_received(:number).with('redis.pool_size', expected_default)
      end
    end
  end

  describe 'WebAuthn設定' do
    describe '#webauthn_rp_name' do
      it 'ApplicationConfig.stringを正しい引数で呼び出すこと' do
        test_class.webauthn_rp_name

        if defined?(Settings)
          expect(ApplicationConfig).to have_received(:string).with('webauthn.rp_name', 'Test App')
        else
          expect(ApplicationConfig).to have_received(:string).with('webauthn.rp_name', 'Shlink-UI-Rails')
        end
      end
    end

    describe '#webauthn_rp_id' do
      it 'ApplicationConfig.stringを正しい引数で呼び出すこと' do
        test_class.webauthn_rp_id

        if defined?(Settings)
          expect(ApplicationConfig).to have_received(:string).with('webauthn.rp_id', 'test.local')
        else
          expect(ApplicationConfig).to have_received(:string).with('webauthn.rp_id', 'localhost')
        end
      end
    end

    describe '#webauthn_origin' do
      it 'ApplicationConfig.stringを正しい引数で呼び出すこと' do
        test_class.webauthn_origin

        if defined?(Settings)
          expect(ApplicationConfig).to have_received(:string).with('webauthn.origin', 'http://test.local:3000')
        else
          expect(ApplicationConfig).to have_received(:string).with('webauthn.origin', 'http://localhost:3000')
        end
      end
    end
  end

  describe 'アプリケーション設定' do
    describe '#pagination_per_page' do
      it 'ApplicationConfig.numberを正しい引数で呼び出すこと' do
        test_class.pagination_per_page

        expected_default = defined?(Settings) ? 20 : 20
        expect(ApplicationConfig).to have_received(:number).with('app.pagination.per_page', expected_default)
      end
    end

    describe '#pagination_max_per_page' do
      it 'ApplicationConfig.numberを正しい引数で呼び出すこと' do
        test_class.pagination_max_per_page

        expected_default = defined?(Settings) ? 100 : 100
        expect(ApplicationConfig).to have_received(:number).with('app.pagination.max_per_page', expected_default)
      end
    end

    describe '#short_url_max_tags' do
      it 'ApplicationConfig.numberを正しい引数で呼び出すこと' do
        test_class.short_url_max_tags

        expected_default = defined?(Settings) ? 10 : 10
        expect(ApplicationConfig).to have_received(:number).with('app.short_url.max_tags', expected_default)
      end
    end

    describe '#short_url_max_tag_length' do
      it 'ApplicationConfig.numberを正しい引数で呼び出すこと' do
        test_class.short_url_max_tag_length

        expected_default = defined?(Settings) ? 20 : 20
        expect(ApplicationConfig).to have_received(:number).with('app.short_url.max_tag_length', expected_default)
      end
    end
  end

  describe 'カテゴリ設定のまとめて取得' do
    describe '#captcha_config' do
      it 'ApplicationConfig.categoryを正しい引数で呼び出すこと' do
        test_class.captcha_config

        expect(ApplicationConfig).to have_received(:category).with('captcha')
      end
    end

    describe '#rate_limit_config' do
      it 'ApplicationConfig.categoryを正しい引数で呼び出すこと' do
        test_class.rate_limit_config

        expect(ApplicationConfig).to have_received(:category).with('rate_limit')
      end
    end

    describe '#email_config' do
      it 'ApplicationConfig.categoryを正しい引数で呼び出すこと' do
        test_class.email_config

        expect(ApplicationConfig).to have_received(:category).with('email')
      end
    end

    describe '#performance_config' do
      it 'ApplicationConfig.categoryを正しい引数で呼び出すこと' do
        test_class.performance_config

        expect(ApplicationConfig).to have_received(:category).with('performance')
      end
    end

    describe '#security_config' do
      it 'ApplicationConfig.categoryを正しい引数で呼び出すこと' do
        test_class.security_config

        expect(ApplicationConfig).to have_received(:category).with('security')
      end
    end

    describe '#system_config' do
      it 'ApplicationConfig.categoryを正しい引数で呼び出すこと' do
        test_class.system_config

        expect(ApplicationConfig).to have_received(:category).with('system')
      end
    end
  end

  describe 'モジュール統合' do
    it 'すべてのメソッドが定義されていること' do
      expect(test_class).to respond_to(:captcha_enabled?)
      expect(test_class).to respond_to(:rate_limit_enabled?)
      expect(test_class).to respond_to(:email_adapter)
      expect(test_class).to respond_to(:shlink_base_url)
      expect(test_class).to respond_to(:performance_cache_ttl)
      expect(test_class).to respond_to(:security_require_2fa?)
      expect(test_class).to respond_to(:system_timezone)
      expect(test_class).to respond_to(:redis_url)
      expect(test_class).to respond_to(:webauthn_rp_name)
      expect(test_class).to respond_to(:pagination_per_page)
      expect(test_class).to respond_to(:captcha_config)
    end
  end
end
