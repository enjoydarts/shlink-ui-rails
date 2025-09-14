require 'rails_helper'

RSpec.describe SystemSetting, type: :model do
  describe 'バリデーション' do
    it 'key_nameが必須であること' do
      setting = build(:system_setting, key_name: nil)
      expect(setting).not_to be_valid
      expect(setting.errors[:key_name]).to include("を入力してください")
    end

    it 'key_nameが一意であること' do
      create(:system_setting, key_name: 'test_key')
      setting = build(:system_setting, key_name: 'test_key')
      expect(setting).not_to be_valid
      expect(setting.errors[:key_name]).to include('はすでに存在します')
    end

    it 'setting_typeが必須であること' do
      setting = build(:system_setting, setting_type: nil)
      expect(setting).not_to be_valid
      expect(setting.errors[:setting_type]).to include("を入力してください")
    end

    it 'setting_typeが有効な値であること' do
      valid_types = %w[string integer boolean json array]
      valid_types.each do |type|
        setting = build(:system_setting, setting_type: type)
        expect(setting).to be_valid
      end
    end

    it 'setting_typeが無効な値の場合はエラー' do
      setting = build(:system_setting, setting_type: 'invalid')
      expect(setting).not_to be_valid
      expect(setting.errors[:setting_type]).to include('は一覧にありません')
    end

    it 'categoryが有効な値であること' do
      valid_categories = SystemSetting::CATEGORIES.values
      valid_categories.each do |category|
        setting = build(:system_setting, category: category)
        expect(setting).to be_valid
      end
    end
  end

  describe 'スコープ' do
    let!(:enabled_setting) { create(:system_setting, enabled: true) }
    let!(:disabled_setting) { create(:system_setting, :disabled) }
    let!(:captcha_setting) { create(:system_setting, category: 'captcha') }
    let!(:email_setting) { create(:system_setting, category: 'email') }

    describe '.enabled' do
      it '有効な設定のみを返すこと' do
        expect(SystemSetting.enabled).to include(enabled_setting)
        expect(SystemSetting.enabled).not_to include(disabled_setting)
      end
    end

    describe '.by_category' do
      it '指定されたカテゴリの設定のみを返すこと' do
        captcha_results = SystemSetting.by_category('captcha')
        expect(captcha_results).to include(captcha_setting)
        expect(captcha_results).not_to include(email_setting)
      end
    end
  end

  describe '#typed_value' do
    context 'string型の場合' do
      it '文字列として値を返すこと' do
        setting = create(:system_setting, setting_type: 'string', value: 'test_value')
        expect(setting.typed_value).to eq('test_value')
      end
    end

    context 'integer型の場合' do
      it '整数として値を返すこと' do
        setting = create(:system_setting, setting_type: 'integer', value: '123')
        expect(setting.typed_value).to eq(123)
      end
    end

    context 'boolean型の場合' do
      it 'true文字列をtrueとして返すこと' do
        setting = create(:system_setting, setting_type: 'boolean', value: 'true')
        expect(setting.typed_value).to be true
      end

      it 'false文字列をfalseとして返すこと' do
        setting = create(:system_setting, setting_type: 'boolean', value: 'false')
        expect(setting.typed_value).to be false
      end
    end

    context 'json型の場合' do
      it 'JSONオブジェクトとして値を返すこと' do
        setting = create(:system_setting, setting_type: 'json', value: '{"key": "value"}')
        expect(setting.typed_value).to eq({ 'key' => 'value' })
      end

      it '無効なJSONの場合はnilを返すこと' do
        setting = create(:system_setting, setting_type: 'json', value: 'invalid json')
        expect(setting.typed_value).to be_nil
      end
    end
  end

  describe '#value=' do
    context 'json型の場合' do
      it 'ハッシュをJSON文字列に変換すること' do
        setting = build(:system_setting, setting_type: 'json')
        setting.value = { key: 'value' }
        expect(setting.value).to eq('{"key":"value"}')
      end
    end

    context 'boolean型の場合' do
      it 'boolean値を文字列に変換すること' do
        setting = build(:system_setting, setting_type: 'boolean')
        setting.value = true
        expect(setting.value).to eq('true')
      end
    end
  end

  describe 'クラスメソッド' do
    describe '.get' do
      let!(:setting) { create(:system_setting, key_name: 'test_key', value: 'test_value', enabled: true) }
      let!(:disabled_setting) { create(:system_setting, key_name: 'disabled_key', value: 'disabled_value', enabled: false) }

      it '有効な設定の値を取得すること' do
        expect(SystemSetting.get('test_key')).to eq('test_value')
      end

      it '無効な設定は無視すること' do
        expect(SystemSetting.get('disabled_key')).to be_nil
      end

      it '存在しない設定はデフォルト値を返すこと' do
        expect(SystemSetting.get('nonexistent', 'default')).to eq('default')
      end
    end

    describe '.set' do
      it '新しい設定を作成すること' do
        SystemSetting.set('new_key', 'new_value', type: 'string', category: 'system')
        setting = SystemSetting.find_by(key_name: 'new_key')
        expect(setting.value).to eq('new_value')
        expect(setting.setting_type).to eq('string')
        expect(setting.category).to eq('system')
      end

      it '既存の設定を更新すること' do
        create(:system_setting, key_name: 'existing_key', value: 'old_value')
        SystemSetting.set('existing_key', 'new_value')
        setting = SystemSetting.find_by(key_name: 'existing_key')
        expect(setting.value).to eq('new_value')
      end
    end

    describe '.by_category_hash' do
      before do
        create(:system_setting, key_name: 'test_captcha.enabled', value: 'true', setting_type: 'boolean', category: 'captcha', enabled: true)
        create(:system_setting, key_name: 'test_captcha.site_key', value: 'test_key', setting_type: 'string', category: 'captcha', enabled: true)
        create(:system_setting, key_name: 'test_captcha.disabled', value: 'disabled', setting_type: 'string', category: 'captcha', enabled: false)
      end

      it 'カテゴリごとの設定をハッシュで返すこと' do
        result = SystemSetting.by_category_hash('captcha')
        expect(result['test_captcha.enabled']).to be true
        expect(result['test_captcha.site_key']).to eq('test_key')
        expect(result).not_to have_key('test_captcha.disabled')
      end
    end

    describe '.initialize_defaults!' do
      it 'デフォルト設定が確実に存在すること' do
        # 既存の設定数を記録
        initial_count = SystemSetting.count

        # initialize_defaults!を実行
        SystemSetting.initialize_defaults!

        # CAPTCHA設定が存在することを確認
        captcha_enabled = SystemSetting.find_by(key_name: 'captcha.enabled')
        expect(captcha_enabled).to be_present
        expect(captcha_enabled.setting_type).to eq('boolean')
        expect(captcha_enabled.category).to eq('captcha')
      end

      it '既存の設定は更新しないこと' do
        # テスト用のユニークなキーを使用
        test_key = 'test.unique_setting'
        existing_setting = create(:system_setting, key_name: test_key, value: 'custom_value')

        SystemSetting.initialize_defaults!
        existing_setting.reload

        expect(existing_setting.value).to eq('custom_value')
      end
    end
  end
end
