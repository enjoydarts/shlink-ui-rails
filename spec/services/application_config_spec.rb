require 'rails_helper'

RSpec.describe ApplicationConfig do
  let(:described_class) { ApplicationConfig }

  before do
    # SystemSettingのモック設定
    stub_const('SystemSetting', double('SystemSetting'))
    allow(SystemSetting).to receive(:table_exists?).and_return(true)

    # Settingsクラスを定義してモック
    settings_class = Class.new do
      def self.respond_to?(method, include_all = false)
        method.to_s == 'redis' ? false : super
      end
    end
    stub_const('Settings', settings_class)

    # ApplicationConfigの既存のモックをクリア
    allow(described_class).to receive(:number).and_call_original
    allow(described_class).to receive(:string).and_call_original
    allow(described_class).to receive(:get).and_call_original

    # キャッシュクリア
    Rails.cache.clear if Rails.env.test?
  end

  after do
    # テスト後のクリーンアップ
    ENV.delete('SHLINK_BASE_URL')
    ENV.delete('REDIS_URL')
    Rails.cache.clear if Rails.env.test?
  end

  describe '.get' do
    context 'SystemSettingに値がある場合' do
      before do
        allow(SystemSetting).to receive(:get).with('shlink.base_url').and_return('https://db.example.com')
      end

      it 'SystemSettingから値を取得すること' do
        result = described_class.get('shlink.base_url')

        expect(result).to eq('https://db.example.com')
        expect(SystemSetting).to have_received(:get).with('shlink.base_url')
      end
    end

    context 'SystemSettingに値がなく環境変数にある場合' do
      before do
        allow(SystemSetting).to receive(:get).with('shlink.base_url').and_return(nil)
        ENV['SHLINK_BASE_URL'] = 'https://env.example.com'
      end

      it '環境変数から値を取得すること' do
        result = described_class.get('shlink.base_url')

        expect(result).to eq('https://env.example.com')
      end
    end

    context 'SystemSettingと環境変数に値がなくSettingsにある場合' do
      before do
        allow(SystemSetting).to receive(:get).with('redis.url').and_return(nil)
        ENV.delete('REDIS_URL')

        # Settingsのモックを設定
        settings_redis = double('Settings Redis')
        allow(settings_redis).to receive(:url).and_return('redis://settings:6379/0')
        allow(Settings).to receive(:respond_to?).and_return(true)
        allow(Settings).to receive(:redis).and_return(settings_redis)
      end

      it 'Settingsから値を取得すること' do
        result = described_class.get('redis.url')

        expect(result).to eq('redis://settings:6379/0')
      end
    end

    context '全ての取得元に値がない場合' do
      before do
        allow(SystemSetting).to receive(:get).with('unknown.key').and_return(nil)
        ENV.delete('UNKNOWN_KEY')
      end

      it 'デフォルト値を返すこと' do
        result = described_class.get('unknown.key', 'default_value')

        expect(result).to eq('default_value')
      end

      it 'デフォルト値がnilの場合はnilを返すこと' do
        result = described_class.get('unknown.key')

        expect(result).to be_nil
      end
    end

    context 'エラーが発生した場合' do
      before do
        allow(SystemSetting).to receive(:get).and_raise(StandardError.new('Database error'))
        allow(Rails.logger).to receive(:error)
      end

      it 'エラーログを出力しデフォルト値を返すこと' do
        result = described_class.get('error.key', 'fallback')

        expect(Rails.logger).to have_received(:error).with(/ApplicationConfig.get error/)
        expect(result).to eq('fallback')
      end
    end
  end

  describe '.enabled?' do
    it 'boolean文字列を正しく解釈すること' do
      allow(described_class).to receive(:get).with('feature.enabled', false).and_return('true')
      expect(described_class.enabled?('feature.enabled')).to be true

      allow(described_class).to receive(:get).with('feature.disabled', false).and_return('false')
      expect(described_class.enabled?('feature.disabled')).to be false

      allow(described_class).to receive(:get).with('feature.on', false).and_return('1')
      expect(described_class.enabled?('feature.on')).to be true

      allow(described_class).to receive(:get).with('feature.off', false).and_return('0')
      expect(described_class.enabled?('feature.off')).to be false
    end

    it '数値を正しく解釈すること' do
      allow(described_class).to receive(:get).with('feature.count', false).and_return(5)
      expect(described_class.enabled?('feature.count')).to be true

      allow(described_class).to receive(:get).with('feature.zero', false).and_return(0)
      expect(described_class.enabled?('feature.zero')).to be false
    end

    it 'その他の値をbooleanに変換すること' do
      allow(described_class).to receive(:get).with('feature.nil', false).and_return(nil)
      expect(described_class.enabled?('feature.nil')).to be false

      allow(described_class).to receive(:get).with('feature.object', false).and_return(Object.new)
      expect(described_class.enabled?('feature.object')).to be true
    end
  end

  describe '.number' do
    it '文字列を数値に変換すること' do
      allow(described_class).to receive(:get).with('limit.max', 0).and_return('100')

      result = described_class.number('limit.max')

      expect(result).to eq(100)
    end

    it 'デフォルト値を正しく処理すること' do
      allow(described_class).to receive(:get).with('limit.unknown', 50).and_return(50)

      result = described_class.number('limit.unknown', 50)

      expect(result).to eq(50)
    end
  end

  describe '.string' do
    it '値を文字列に変換すること' do
      allow(described_class).to receive(:get).with('app.name', '').and_return(123)

      result = described_class.string('app.name')

      expect(result).to eq('123')
    end

    it 'デフォルト値を返すこと' do
      allow(described_class).to receive(:get).with('app.unknown', '').and_return('default')

      result = described_class.string('app.unknown')

      expect(result).to eq('default')
    end
  end

  describe '.array' do
    it '配列をそのまま返すこと' do
      allow(described_class).to receive(:get).with('list.items', []).and_return([ 'a', 'b', 'c' ])

      result = described_class.array('list.items')

      expect(result).to eq([ 'a', 'b', 'c' ])
    end

    it 'JSON文字列を配列に変換すること' do
      allow(described_class).to receive(:get).with('list.json', []).and_return('["x", "y", "z"]')

      result = described_class.array('list.json')

      expect(result).to eq([ 'x', 'y', 'z' ])
    end

    it 'CSV文字列を配列に変換すること' do
      allow(described_class).to receive(:get).with('list.csv', []).and_return('one, two, three')

      result = described_class.array('list.csv')

      expect(result).to eq([ 'one', 'two', 'three' ])
    end

    it 'その他の値を配列に変換すること' do
      allow(described_class).to receive(:get).with('list.single', []).and_return('single')

      result = described_class.array('list.single')

      expect(result).to eq([ 'single' ])
    end
  end

  describe '.set' do
    context 'SystemSettingが利用可能な場合' do
      before do
        allow(SystemSetting).to receive(:set)
        allow(described_class).to receive(:clear_cache!)
      end

      it '値を正常に設定すること' do
        result = described_class.set('test.key', 'test_value', type: 'string', category: 'test')

        expect(SystemSetting).to have_received(:set).with('test.key', 'test_value', {
          type: 'string',
          category: 'test',
          description: nil
        })
        expect(described_class).to have_received(:clear_cache!)
        expect(result).to be true
      end
    end

    context 'SystemSettingが利用できない場合' do
      before do
        allow(SystemSetting).to receive(:table_exists?).and_return(false)
      end

      it 'falseを返すこと' do
        result = described_class.set('test.key', 'test_value')

        expect(result).to be false
      end
    end
  end

  describe '.reset' do
    context 'SystemSettingが利用可能な場合' do
      let(:system_setting_relation) { double('SystemSetting Relation') }

      before do
        allow(SystemSetting).to receive(:where).with(key_name: 'test.key').and_return(system_setting_relation)
        allow(system_setting_relation).to receive(:destroy_all)
        allow(described_class).to receive(:clear_cache!)
      end

      it '設定を正常にリセットすること' do
        result = described_class.reset('test.key')

        expect(SystemSetting).to have_received(:where).with(key_name: 'test.key')
        expect(system_setting_relation).to have_received(:destroy_all)
        expect(described_class).to have_received(:clear_cache!)
        expect(result).to be true
      end
    end

    context 'SystemSettingが利用できない場合' do
      before do
        allow(SystemSetting).to receive(:table_exists?).and_return(false)
      end

      it 'falseを返すこと' do
        result = described_class.reset('test.key')

        expect(result).to be false
      end
    end
  end

  describe '.reload!' do
    before do
      allow(described_class).to receive(:clear_cache!)
      allow(described_class).to receive(:get).with('system.timezone', 'Tokyo').and_return('UTC')
      allow(described_class).to receive(:get).with('system.log_level', 'info').and_return('debug')
      allow(Time).to receive(:zone=)
      allow(Rails.logger).to receive(:level=)
      allow(Rails.logger).to receive(:info)
    end

    it '設定を再読み込みすること' do
      result = described_class.reload!

      expect(described_class).to have_received(:clear_cache!)
      expect(Time).to have_received(:zone=).with('UTC')
      expect(Rails.logger).to have_received(:level=).with(Logger::DEBUG)
      expect(Rails.logger).to have_received(:info).with(/ApplicationConfig reloaded/)
      expect(result).to be true
    end
  end

  describe 'private methods' do
    describe '#parse_env_value' do
      it 'boolean値を正しく解析すること' do
        expect(described_class.send(:parse_env_value, 'true')).to be true
        expect(described_class.send(:parse_env_value, 'false')).to be false
        expect(described_class.send(:parse_env_value, '1')).to be true
        expect(described_class.send(:parse_env_value, '0')).to be false
      end

      it '数値を正しく解析すること' do
        expect(described_class.send(:parse_env_value, '123')).to eq(123)
        expect(described_class.send(:parse_env_value, '45.67')).to eq(45.67)
      end

      it 'JSON形式を正しく解析すること' do
        expect(described_class.send(:parse_env_value, '{"key": "value"}')).to eq({ 'key' => 'value' })
        expect(described_class.send(:parse_env_value, '[1, 2, 3]')).to eq([ 1, 2, 3 ])
      end

      it '文字列をそのまま返すこと' do
        expect(described_class.send(:parse_env_value, 'simple_string')).to eq('simple_string')
      end
    end

    describe '#flatten_hash' do
      it 'ネストしたハッシュを平坦化すること' do
        nested_hash = {
          'database' => {
            'host' => 'localhost',
            'port' => 5432,
            'config' => {
              'timeout' => 30
            }
          },
          'simple' => 'value'
        }

        result = described_class.send(:flatten_hash, nested_hash, 'app.')

        expect(result).to eq({
          'app.database.host' => 'localhost',
          'app.database.port' => 5432,
          'app.database.config.timeout' => 30,
          'app.simple' => 'value'
        })
      end
    end

    describe '#get_from_settings' do
      context 'Settingsが利用可能な場合' do
        let(:settings_database) { double('Settings Database') }

        before do
          # Settingsクラスを完全に再定義して設定をクリア
          settings_class = Class.new do
            def self.respond_to?(method, include_all = false)
              method.to_s == 'database'
            end

            def self.database
              database_obj = OpenStruct.new
              database_obj.define_singleton_method(:respond_to?) { |m, ia = false| m.to_s == 'host' }
              database_obj.define_singleton_method(:host) { 'settings.example.com' }
              database_obj
            end
          end
          stub_const('Settings', settings_class)
        end

        it 'ネストした設定値を取得すること' do
          result = described_class.send(:get_from_settings, 'database.host')

          expect(result).to eq('settings.example.com')
        end

        context '存在しないキーを指定した場合' do
          before do
            # 非存在キー用のSettingsクラスを再定義
            settings_class = Class.new do
              def self.respond_to?(method, include_all = false)
                false
              end
            end
            stub_const('Settings', settings_class)
          end

          it 'nilを返すこと' do
            result = described_class.send(:get_from_settings, 'nonexistent.key')

            expect(result).to be_nil
          end
        end
      end

      context 'Settingsが利用できない場合' do
        before do
          stub_const('Settings', nil) if defined?(Settings)
          allow(Rails.logger).to receive(:debug)
        end

        it 'nilを返すこと' do
          result = described_class.send(:get_from_settings, 'any.key')

          expect(result).to be_nil
        end
      end
    end
  end
end
