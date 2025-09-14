require 'rails_helper'

RSpec.describe MailAdapter::SmtpAdapter do
  let(:adapter) { described_class.new }

  describe '#initialize' do
    it '正常に初期化できること' do
      expect { described_class.new }.not_to raise_error
    end
  end

  describe '#deliver_mail' do
    let(:mail_object) { double('ActionMailer::MessageDelivery', subject: 'テストメール') }

    before do
      allow(Rails.logger).to receive(:info)
    end

    context 'メール送信が成功する場合' do
      before do
        allow(mail_object).to receive(:deliver_now).and_return(true)
      end

      it 'trueを返すこと' do
        result = adapter.deliver_mail(mail_object)
        expect(result).to be true
      end

      it '開始ログを出力すること' do
        expect(Rails.logger).to receive(:info).with(/SMTP経由でメール送信を開始/)
        adapter.deliver_mail(mail_object)
      end

      it '完了ログを出力すること' do
        expect(Rails.logger).to receive(:info).with(/SMTP経由でメール送信が完了/)
        adapter.deliver_mail(mail_object)
      end
    end

    context 'Net::SMTPErrorが発生する場合' do
      let(:smtp_error) { Net::SMTPServerBusy.new('SMTP server error') }

      before do
        allow(mail_object).to receive(:deliver_now).and_raise(smtp_error)
        allow(Rails.logger).to receive(:error)
      end

      it 'MailAdapter::BaseAdapter::Errorを発生させること' do
        expect { adapter.deliver_mail(mail_object) }.to raise_error(
          MailAdapter::BaseAdapter::Error,
          /SMTP送信エラー/
        )
      end

      it 'エラーログを出力すること' do
        expect(Rails.logger).to receive(:error).with(/SMTP送信エラー/)
        expect { adapter.deliver_mail(mail_object) }.to raise_error(MailAdapter::BaseAdapter::Error)
      end

      it '元のエラーを保持すること' do
        begin
          adapter.deliver_mail(mail_object)
        rescue MailAdapter::BaseAdapter::Error => e
          expect(e.original_error).to eq(smtp_error)
        end
      end
    end

    context 'Timeout::Errorが発生する場合' do
      let(:timeout_error) { Timeout::Error.new('Connection timeout') }

      before do
        allow(mail_object).to receive(:deliver_now).and_raise(timeout_error)
        allow(Rails.logger).to receive(:error)
      end

      it 'MailAdapter::BaseAdapter::Errorを発生させること' do
        expect { adapter.deliver_mail(mail_object) }.to raise_error(
          MailAdapter::BaseAdapter::Error,
          /SMTP送信エラー/
        )
      end
    end

    context 'SocketErrorが発生する場合' do
      let(:socket_error) { SocketError.new('Connection refused') }

      before do
        allow(mail_object).to receive(:deliver_now).and_raise(socket_error)
        allow(Rails.logger).to receive(:error)
      end

      it 'MailAdapter::BaseAdapter::Errorを発生させること' do
        expect { adapter.deliver_mail(mail_object) }.to raise_error(
          MailAdapter::BaseAdapter::Error,
          /SMTP送信エラー/
        )
      end
    end

    context '予期しないエラーが発生する場合' do
      let(:unexpected_error) { StandardError.new('Unexpected error') }

      before do
        allow(mail_object).to receive(:deliver_now).and_raise(unexpected_error)
        allow(Rails.logger).to receive(:error)
      end

      it 'MailAdapter::BaseAdapter::Errorを発生させること' do
        expect { adapter.deliver_mail(mail_object) }.to raise_error(
          MailAdapter::BaseAdapter::Error,
          /メール送信で予期しないエラーが発生/
        )
      end
    end
  end

  describe '#available?' do
    it '常にtrueを返すこと' do
      expect(adapter.available?).to be true
    end
  end

  describe '#configured?' do
    context '開発環境の場合' do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development')) }

      it 'trueを返すこと' do
        expect(adapter.configured?).to be true
      end
    end

    context 'テスト環境の場合' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('test'))
        mock_smtp_settings
      end

      it 'trueを返すこと' do
        expect(adapter.configured?).to be true
      end
    end

    context '本番環境の場合' do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production')) }

      context '必要な設定がすべて存在する場合' do
        before { mock_smtp_settings }

        it 'trueを返すこと' do
          expect(adapter.configured?).to be true
        end
      end

      context '一部の設定が不足している場合' do
        before { mock_incomplete_smtp_settings }

        it 'falseを返すこと' do
          expect(adapter.configured?).to be false
        end
      end

      context '設定の取得でエラーが発生した場合' do
        before do
          allow(SystemSetting).to receive(:get).with("email.adapter", "smtp").and_return("smtp")
          allow(SystemSetting).to receive(:get).with("email.smtp_address", "").and_raise(StandardError.new('設定エラー'))
          allow(Rails.logger).to receive(:error)
        end

        it 'falseを返すこと' do
          expect(adapter.configured?).to be false
        end

        it 'エラーログを出力すること' do
          expect(Rails.logger).to receive(:error).with(/SMTP設定の確認中にエラーが発生/)
          adapter.configured?
        end
      end
    end
  end
end
