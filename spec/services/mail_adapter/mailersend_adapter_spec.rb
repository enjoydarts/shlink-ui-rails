require 'rails_helper'

RSpec.describe MailAdapter::MailersendAdapter do
  let(:mail_object) { instance_double('ActionMailer::MessageDelivery') }
  let(:mail_message) { instance_double('Mail::Message') }
  let(:mailersend_client) { instance_double('Mailersend::Email') }

  before do
    mock_mailersend_settings
    # Mailersendクラスとモジュールをスタブ
    stub_const('::Mailersend', Module.new)
    stub_const('::Mailersend::Error', Class.new(StandardError))
    mailersend_client_class = Class.new do
      def initialize(api_key)
        @api_key = api_key
      end
    end
    stub_const('::Mailersend::Client', mailersend_client_class)
    mailersend_email_class = Class.new do
      attr_accessor :api_token

      def initialize(client)
        @client = client
      end

      def send_email(payload)
        # テスト用のデフォルト実装
      end
    end
    stub_const('::Mailersend::Email', mailersend_email_class)
    allow(::Mailersend::Email).to receive(:new).and_return(mailersend_client)
    allow(mailersend_client).to receive(:api_token=)

    # MailerSend v3 API対応のメソッドをモック
    allow(mailersend_client).to receive(:add_from)
    allow(mailersend_client).to receive(:add_recipients)
    allow(mailersend_client).to receive(:add_subject)
    allow(mailersend_client).to receive(:add_html)
    allow(mailersend_client).to receive(:add_text)
    allow(mailersend_client).to receive(:add_cc)
    allow(mailersend_client).to receive(:add_bcc)
    allow(mailersend_client).to receive(:send)
  end

  let(:adapter) { described_class.new }

  describe '#initialize' do
    context '設定が正しい場合' do
      it '正常に初期化できること' do
        expect { described_class.new }.not_to raise_error
      end
    end

    context '設定が不完全な場合' do
      before { mock_incomplete_mailersend_settings }

      it '初期化できるが設定チェックで失敗すること' do
        adapter = described_class.new
        expect(adapter.configured?).to be false
      end
    end
  end

  describe '#deliver_mail' do
    let(:successful_response) { instance_double('Response') }

    before do
      allow(mail_object).to receive(:message).and_return(mail_message)
      allow(mail_message).to receive(:subject).and_return('テストメール')
      allow(mail_message).to receive(:to).and_return([ 'recipient@example.com' ])
      allow(mail_message).to receive(:cc).and_return([])
      allow(mail_message).to receive(:bcc).and_return([])
      allow(mail_message).to receive(:multipart?).and_return(false)
      allow(mail_message).to receive(:content_type).and_return('text/html')
      allow(mail_message).to receive(:body).and_return(instance_double('Mail::Body', decoded: '<p>テストメッセージ</p>'))
      allow(mail_message).to receive(:html_part).and_return(nil)
      allow(mail_message).to receive(:text_part).and_return(nil)

      allow(::Mailersend::Email).to receive(:new).and_return(mailersend_client)
      allow(mailersend_client).to receive(:api_token=)
      allow(Rails.logger).to receive(:info)
    end

    context 'アダプタが設定されていない場合' do
      before do
        allow_any_instance_of(described_class).to receive(:configured?).and_return(false)
      end

      it 'MailersendErrorを発生させること' do
        expect { adapter.deliver_mail(mail_object) }.to raise_error(
          MailAdapter::MailersendAdapter::MailersendError,
          /MailerSend設定が不完全です/
        )
      end
    end

    context 'メール送信が成功する場合' do
      before do
        allow(mailersend_client).to receive(:send).and_return(successful_response)

        # メールオブジェクトのモック設定
        mail_message = instance_double('Mail::Message')
        allow(mail_message).to receive(:subject).and_return('Test Subject')
        allow(mail_message).to receive(:to).and_return([ 'test@example.com' ])
        allow(mail_message).to receive(:cc).and_return(nil)
        allow(mail_message).to receive(:bcc).and_return(nil)
        allow(mail_message).to receive(:html_part).and_return(nil)
        allow(mail_message).to receive(:text_part).and_return(nil)
        allow(mail_message).to receive(:multipart?).and_return(false)

        body_double = double('body')
        allow(body_double).to receive(:decoded).and_return('Test message body')
        allow(mail_message).to receive(:body).and_return(body_double)
        allow(mail_object).to receive(:message).and_return(mail_message)
      end

      it 'trueを返すこと' do
        result = adapter.deliver_mail(mail_object)
        expect(result).to be true
      end

      it '開始ログを出力すること' do
        expect(Rails.logger).to receive(:info).with(/MailerSend API経由でメール送信を開始/)
        adapter.deliver_mail(mail_object)
      end

      it '完了ログを出力すること' do
        expect(Rails.logger).to receive(:info).with(/MailerSend API経由でメール送信が完了/)
        adapter.deliver_mail(mail_object)
      end

      it '正しいメソッドでAPIを呼び出すこと' do
        expect(mailersend_client).to receive(:add_from).with("email" => "test@example.com", "name" => "Test App")
        expect(mailersend_client).to receive(:add_recipients).with("email" => "test@example.com")
        expect(mailersend_client).to receive(:add_subject).with("Test Subject")
        expect(mailersend_client).to receive(:add_text).with("Test message body")
        expect(mailersend_client).to receive(:send)
        adapter.deliver_mail(mail_object)
      end
    end

    context 'MailerSend APIが失敗する場合' do
      let(:failed_response) { instance_double('Response', message: 'API Error') }

      before do
        allow(mailersend_client).to receive(:send).and_return(failed_response)
        allow(Rails.logger).to receive(:error)
      end

      it 'MailersendErrorを発生させること' do
        expect { adapter.deliver_mail(mail_object) }.to raise_error(
          MailAdapter::MailersendAdapter::MailersendError,
          /MailerSend API送信失敗/
        )
      end
    end

    context 'Mailersend::Errorが発生する場合' do
      let(:mailersend_error) { ::Mailersend::Error.new('API connection failed') }

      before do
        allow(mailersend_client).to receive(:send).and_raise(mailersend_error)
        allow(Rails.logger).to receive(:error)
      end

      it 'MailersendErrorを発生させること' do
        expect { adapter.deliver_mail(mail_object) }.to raise_error(
          MailAdapter::MailersendAdapter::MailersendError,
          /MailerSend APIエラー/
        )
      end
    end

    context '予期しないエラーが発生する場合' do
      let(:unexpected_error) { StandardError.new('Unexpected error') }

      before do
        allow(mailersend_client).to receive(:send).and_raise(unexpected_error)
        allow(Rails.logger).to receive(:error)
      end

      it 'MailersendErrorを発生させること' do
        expect { adapter.deliver_mail(mail_object) }.to raise_error(
          MailAdapter::MailersendAdapter::MailersendError,
          /MailerSend送信で予期しないエラーが発生/
        )
      end
    end

    context 'マルチパートメールの場合' do
      let(:html_part) { instance_double('Mail::Part', content_type: 'text/html', body: instance_double('Mail::Body', decoded: '<p>HTML content</p>')) }
      let(:text_part) { instance_double('Mail::Part', content_type: 'text/plain', body: instance_double('Mail::Body', decoded: 'Text content')) }

      before do
        allow(mail_message).to receive(:multipart?).and_return(true)
        allow(mail_message).to receive(:parts).and_return([ html_part, text_part ])
        allow(mailersend_client).to receive(:send).and_return(successful_response)
      end

      it 'HTMLとテキストの両方のコンテンツを含むこと' do
        expect(mailersend_client).to receive(:add_html).with('<p>HTML content</p>')
        expect(mailersend_client).to receive(:add_text).with('Text content')
        expect(mailersend_client).to receive(:send)
        adapter.deliver_mail(mail_object)
      end
    end

    context 'CC/BCCが含まれる場合' do
      before do
        allow(mail_message).to receive(:cc).and_return([ 'cc@example.com' ])
        allow(mail_message).to receive(:bcc).and_return([ 'bcc@example.com' ])
        allow(mailersend_client).to receive(:send).and_return(successful_response)
      end

      it 'CC/BCCを含むペイロードを送信すること' do
        expect(mailersend_client).to receive(:add_cc).with("email" => "cc@example.com")
        expect(mailersend_client).to receive(:add_bcc).with("email" => "bcc@example.com")
        expect(mailersend_client).to receive(:send)
        adapter.deliver_mail(mail_object)
      end
    end
  end

  describe '#available?' do
    context '設定が正しくgemが利用可能な場合' do
      it 'trueを返すこと' do
        expect(adapter.available?).to be true
      end
    end

    context '設定が不正な場合' do
      before do
        mock_incomplete_mailersend_settings
        allow(Rails.logger).to receive(:error)
      end

      it 'falseを返すこと' do
        adapter = described_class.new
        expect(adapter.available?).to be false
      end
    end
  end

  describe '#configured?' do
    context '必要な設定がすべて存在する場合' do
      it 'trueを返すこと' do
        expect(adapter.configured?).to be true
      end
    end

    context 'API キーが空の場合' do
      before { mock_incomplete_mailersend_settings }

      it 'falseを返すこと' do
        adapter = described_class.new
        expect(adapter.configured?).to be false
      end
    end

    context '送信者メールアドレスが空の場合' do
      before do
        allow(SystemSetting).to receive(:get).with("email.adapter", "smtp").and_return('mailersend')
        allow(SystemSetting).to receive(:get).with("email.mailersend_api_key", "").and_return('test-api-key')
        allow(SystemSetting).to receive(:get).with("email.from_address", "noreply@example.com").and_return('')
        allow(SystemSetting).to receive(:get).with("system.site_name", "Shlink-UI-Rails").and_return('Test App')
      end

      it 'falseを返すこと' do
        adapter = described_class.new
        expect(adapter.configured?).to be false
      end
    end

    context '設定の取得でエラーが発生した場合' do
      before do
        allow(SystemSetting).to receive(:get).with("email.mailersend_api_key", "").and_raise(StandardError.new('設定エラー'))
        allow(Rails.logger).to receive(:error)
      end

      it 'falseを返すこと' do
        adapter = described_class.new
        expect(adapter.configured?).to be false
      end

      it 'エラーログを出力すること' do
        expect(Rails.logger).to receive(:error).with(/MailerSend設定の初期化中にエラーが発生/)
        described_class.new
      end
    end
  end
end
