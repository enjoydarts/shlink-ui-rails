require 'rails_helper'

RSpec.describe ApplicationMailer do
  describe 'default from address' do
    let(:test_mailer) { Class.new(ApplicationMailer) }

    context '本番環境でMailerSendを使用する場合' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
        allow(Settings).to receive(:mail_delivery_method).and_return('mailersend')
        allow(Settings).to receive(:mailersend).and_return(
          OpenStruct.new(
            from_email: 'noreply@example.com',
            from_name: 'Example App'
          )
        )
      end

      it 'MailerSend設定からのfrom addressを使用すること' do
        # test_mailerクラスのインスタンスを作成してdefault_from_addressを呼び出す
        mailer_instance = test_mailer.new
        from_address = mailer_instance.send(:default_from_address)
        expect(from_address).to eq('Example App <noreply@example.com>')
      end
    end

    context '本番環境でSMTPを使用する場合' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
        allow(Settings).to receive(:mail_delivery_method).and_return('smtp')
        allow(Settings).to receive(:mailer).and_return(
          OpenStruct.new(from: 'smtp@example.com')
        )
      end

      it 'SMTP設定からのfrom addressを使用すること' do
        mailer_instance = test_mailer.new
        from_address = mailer_instance.send(:default_from_address)
        expect(from_address).to eq('smtp@example.com')
      end
    end

    context '開発環境の場合' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))
      end

      it 'デフォルトのfrom addressを使用すること' do
        mailer_instance = test_mailer.new
        from_address = mailer_instance.send(:default_from_address)
        expect(from_address).to eq('from@example.com')
      end
    end

    context 'テスト環境の場合' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('test'))
      end

      it 'デフォルトのfrom addressを使用すること' do
        mailer_instance = test_mailer.new
        from_address = mailer_instance.send(:default_from_address)
        expect(from_address).to eq('from@example.com')
      end
    end

    context '本番環境でSMTPを使用するがmailer.fromが空の場合' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
        allow(Settings).to receive(:mail_delivery_method).and_return('smtp')
        allow(Settings).to receive(:mailer).and_return(
          OpenStruct.new(from: nil)
        )
      end

      it 'デフォルトのfrom addressを使用すること' do
        mailer_instance = test_mailer.new
        from_address = mailer_instance.send(:default_from_address)
        expect(from_address).to eq('from@example.com')
      end
    end

    context '設定の取得でエラーが発生した場合' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
        allow(Settings).to receive(:mail_delivery_method).and_raise(StandardError.new('設定エラー'))
        allow(Rails.logger).to receive(:error)
      end

      it 'デフォルトのfrom addressを使用すること' do
        mailer_instance = test_mailer.new
        from_address = mailer_instance.send(:default_from_address)
        expect(from_address).to eq('from@example.com')
      end

      it 'エラーログを出力すること' do
        expect(Rails.logger).to receive(:error).with(/送信者アドレス取得中にエラーが発生/)
        mailer_instance = test_mailer.new
        mailer_instance.send(:default_from_address)
      end
    end
  end

  describe 'layout configuration' do
    it 'mailerレイアウトが設定されていること' do
      expect(ApplicationMailer._layout).to eq('mailer')
    end
  end

  describe 'default from configuration' do
    it 'defaultのfromがProcで設定されていること' do
      expect(ApplicationMailer.default[:from]).to be_a(Proc)
    end
  end
end
