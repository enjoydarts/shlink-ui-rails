# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationRecord, type: :model do
  describe 'ベースモデルクラス' do
    it '抽象クラスであること' do
      expect(described_class).to be_abstract_class
    end

    it 'ActiveRecord::Baseを継承していること' do
      expect(described_class.superclass).to eq(ActiveRecord::Base)
    end
  end

  describe 'ConfigShortcutsの組み込み' do
    it 'ConfigShortcutsモジュールをインクルードしていること' do
      expect(described_class.included_modules).to include(ConfigShortcuts)
    end

    it '子クラスに設定ショートカットメソッドを提供すること' do
      # ConfigShortcutsはインスタンスメソッドを提供するため、クラスメソッドとしてはアクセスできない
      expect(User.included_modules).to include(ConfigShortcuts)
    end

    it 'インスタンスに設定ショートカットメソッドを提供すること' do
      user = create(:user)
      expect(user).to respond_to(:shlink_base_url)
      expect(user).to respond_to(:email_adapter)
      expect(user).to respond_to(:captcha_enabled?)
    end

    it '子モデルから設定にアクセスできること' do
      allow(ApplicationConfig).to receive(:string).with('shlink.base_url', anything).and_return('test-url')

      user = create(:user)
      expect(user.shlink_base_url).to eq('test-url')
    end
  end

  describe '子モデルの継承' do
    it 'UserモデルがApplicationRecordを継承していること' do
      expect(User.superclass).to eq(described_class)
    end

    it 'SystemSettingモデルがApplicationRecordを継承していること' do
      expect(SystemSetting.superclass).to eq(described_class)
    end

    it 'ShortUrlモデルがApplicationRecordを継承していること' do
      expect(ShortUrl.superclass).to eq(described_class)
    end

    it 'WebauthnCredentialモデルがApplicationRecordを継承していること' do
      expect(WebauthnCredential.superclass).to eq(described_class)
    end

    it '各モデルがApplicationRecordの機能を継承していること' do
      expect(User.included_modules).to include(ConfigShortcuts)
      expect(SystemSetting.included_modules).to include(ConfigShortcuts)
      expect(ShortUrl.included_modules).to include(ConfigShortcuts)
      expect(WebauthnCredential.included_modules).to include(ConfigShortcuts)
    end

    it '抽象クラスの設定が正しく動作すること' do
      expect { described_class.new }.to raise_error(NotImplementedError)
    end
  end
end
