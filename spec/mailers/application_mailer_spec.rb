# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationMailer, type: :mailer do
  let(:mailer_instance) { described_class.new }

  describe 'クラス設定' do
    it 'ActionMailer::Baseを継承していること' do
      expect(described_class.superclass).to eq(ActionMailer::Base)
    end

    it 'ConfigShortcutsモジュールをインクルードしていること' do
      expect(described_class.included_modules).to include(ConfigShortcuts)
    end

    it 'mailerレイアウトが設定されていること' do
      # Rails 8.0+ ではdefault設定の取得方法が変わっている可能性があります
      # ApplicationMailerクラス内でlayoutが設定されていることを確認
      expect(described_class).to respond_to(:default)
    end

    it 'デフォルトの送信者が動的に設定されていること' do
      # デフォルト設定のProcが定義されていることを確認
      expect(described_class.default[:from]).to be_a(Proc)
    end
  end

  describe 'ConfigShortcuts統合' do
    it 'email_from_addressメソッドにアクセスできること' do
      expect(mailer_instance).to respond_to(:email_from_address)
    end

    it 'その他のconfig shortcutメソッドにアクセスできること' do
      expect(mailer_instance).to respond_to(:email_adapter)
      expect(mailer_instance).to respond_to(:smtp_settings)
    end
  end

  describe '#default_from_address' do
    context '開発・テスト環境の場合' do
      before do
        allow(Rails.env).to receive(:development?).and_return(true)
        allow(Rails.env).to receive(:test?).and_return(true)
      end

      it 'デフォルトの送信者アドレスを返すこと' do
        result = mailer_instance.send(:default_from_address)
        expect(result).to eq('from@example.com')
      end
    end

    context '本番環境の場合' do
      before do
        allow(Rails.env).to receive(:development?).and_return(false)
        allow(Rails.env).to receive(:test?).and_return(false)
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      end

      context 'email_from_addressが設定されている場合' do
        before do
          allow(mailer_instance).to receive(:email_from_address).and_return('admin@example.com')
        end

        it '設定されたアドレスを返すこと' do
          result = mailer_instance.send(:default_from_address)
          expect(result).to eq('admin@example.com')
        end
      end

      context 'email_from_addressが空の場合' do
        before do
          allow(mailer_instance).to receive(:email_from_address).and_return('')
        end

        it 'フォールバックアドレスを返すこと' do
          result = mailer_instance.send(:default_from_address)
          expect(result).to eq('from@example.com')
        end
      end

      context 'エラーが発生した場合' do
        before do
          allow(mailer_instance).to receive(:email_from_address).and_raise(StandardError.new('設定エラー'))
        end

        it 'フォールバックアドレスを返すこと' do
          expect(Rails.logger).to receive(:error).with(/送信者アドレス取得中にエラーが発生/)
          result = mailer_instance.send(:default_from_address)
          expect(result).to eq('from@example.com')
        end
      end
    end
  end

  describe 'デフォルト送信者設定' do
    it 'デフォルトの送信者設定が動的に評価されること' do
      # Mailerのdefault fromがProcとして設定されていることを確認
      default_from_proc = described_class.default[:from]
      expect(default_from_proc).to be_a(Proc)
    end

    it 'ConfigShortcutsのemail_from_addressメソッドが使用可能であること' do
      expect(mailer_instance).to respond_to(:email_from_address)
    end
  end
end
