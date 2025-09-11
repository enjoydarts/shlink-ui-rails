require 'rails_helper'

RSpec.describe MailAdapter::Factory do
  before do
    # Mailersendクラスとモジュールをスタブ
    stub_const('::Mailersend', Module.new)
    stub_const('::Mailersend::Error', Class.new(StandardError))
    mailersend_email_class = Class.new do
      attr_accessor :api_token
      def send_email(payload)
        # テスト用のデフォルト実装
      end
    end
    stub_const('::Mailersend::Email', mailersend_email_class)
  end
  describe '.create_adapter' do
    context '開発環境の場合' do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development')) }

      it 'SMTPアダプタを返すこと' do
        adapter = described_class.create_adapter
        expect(adapter).to be_a(MailAdapter::SmtpAdapter)
      end
    end

    context 'テスト環境の場合' do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('test')) }

      it 'SMTPアダプタを返すこと' do
        adapter = described_class.create_adapter
        expect(adapter).to be_a(MailAdapter::SmtpAdapter)
      end
    end

    context '本番環境の場合' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
      end

      context 'mail_delivery_methodがsmtpの場合' do
        before { mock_smtp_settings }

        it 'SMTPアダプタを返すこと' do
          adapter = described_class.create_adapter
          expect(adapter).to be_a(MailAdapter::SmtpAdapter)
        end
      end

      context 'mail_delivery_methodがmailersendの場合' do
        before { mock_mailersend_settings }

        it 'MailerSendアダプタを返すこと' do
          adapter = described_class.create_adapter
          expect(adapter).to be_a(MailAdapter::MailersendAdapter)
        end
      end

      context 'mail_delivery_methodが無効な値の場合' do
        before do
          mock_invalid_settings
          allow(Rails.logger).to receive(:warn)
        end

        it 'SMTPアダプタを返すこと' do
          adapter = described_class.create_adapter
          expect(adapter).to be_a(MailAdapter::SmtpAdapter)
        end

        it '警告ログを出力すること' do
          expect(Rails.logger).to receive(:warn).with(/不明な配信方式設定/)
          described_class.create_adapter
        end
      end

      context '設定の取得でエラーが発生した場合' do
        before do
          mock_settings_error
          allow(Rails.logger).to receive(:error)
        end

        it 'SMTPアダプタを返すこと' do
          adapter = described_class.create_adapter
          expect(adapter).to be_a(MailAdapter::SmtpAdapter)
        end

        it 'エラーログを出力すること' do
          expect(Rails.logger).to receive(:error).with(/アダプタタイプ決定中にエラー/)
          described_class.create_adapter
        end
      end
    end

    context 'アダプタが利用できない場合' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('test'))
        adapter_mock = instance_double(MailAdapter::SmtpAdapter)
        allow(MailAdapter::SmtpAdapter).to receive(:new).and_return(adapter_mock)
        allow(adapter_mock).to receive(:available?).and_return(false)
      end

      it 'FactoryErrorを発生させること' do
        expect { described_class.create_adapter }.to raise_error(
          MailAdapter::Factory::FactoryError,
          /smtpアダプタは利用できません/
        )
      end
    end

    context 'アダプタの設定が不完全な場合' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('test'))
        adapter_mock = instance_double(MailAdapter::SmtpAdapter)
        allow(MailAdapter::SmtpAdapter).to receive(:new).and_return(adapter_mock)
        allow(adapter_mock).to receive(:available?).and_return(true)
        allow(adapter_mock).to receive(:configured?).and_return(false)
      end

      it 'FactoryErrorを発生させること' do
        expect { described_class.create_adapter }.to raise_error(
          MailAdapter::Factory::FactoryError,
          /smtpアダプタの設定が不完全です/
        )
      end
    end

    context '未対応のアダプタタイプの場合' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
        stub_const('MailAdapter::Factory::SUPPORTED_ADAPTERS', [ 'smtp' ])
        allow(Settings).to receive(:mail_delivery_method).and_return('mailersend')
      end

      it 'SMTPアダプタにフォールバックすること' do
        adapter = described_class.create_adapter
        expect(adapter).to be_a(MailAdapter::SmtpAdapter)
      end
    end
  end
end
