require 'rails_helper'

RSpec.describe MailAdapter::LetterOpenerAdapter do
  let(:adapter) { described_class.new }

  describe '#initialize' do
    it '正常に初期化できること' do
      expect { described_class.new }.not_to raise_error
    end

    it '適切な名前と識別子が設定されること' do
      expect(adapter.instance_variable_get(:@name)).to eq("Letter Opener")
      expect(adapter.instance_variable_get(:@identifier)).to eq("letter_opener")
    end
  end

  describe '#available?' do
    context '開発環境の場合' do
      before do
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it 'trueを返すこと' do
        expect(adapter.available?).to be true
      end
    end

    context '本番環境の場合' do
      before do
        allow(Rails.env).to receive(:development?).and_return(false)
      end

      it 'falseを返すこと' do
        expect(adapter.available?).to be false
      end
    end
  end

  describe '#configured?' do
    it '常にtrueを返すこと' do
      expect(adapter.configured?).to be true
    end
  end

  describe '#deliver_mail' do
    let(:mail_object) do
      double('ActionMailer::MessageDelivery',
        subject: 'テストメール',
        to: [ 'test@example.com' ],
        deliver_now: true
      )
    end

    before do
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:error)
    end

    context 'メール送信が成功する場合' do
      it 'trueを返すこと' do
        expect(adapter.deliver_mail(mail_object)).to be true
      end

      it 'deliver_nowが呼び出されること' do
        expect(mail_object).to receive(:deliver_now)
        adapter.deliver_mail(mail_object)
      end

      it 'ログが出力されること' do
        expect(Rails.logger).to receive(:info).with(/Letter Opener経由でメール送信開始/)
        expect(Rails.logger).to receive(:info).with(/宛先: test@example.com/)
        expect(Rails.logger).to receive(:info).with(/件名: テストメール/)
        expect(Rails.logger).to receive(:info).with(/Letter Openerでメール送信完了/)

        adapter.deliver_mail(mail_object)
      end
    end

    context 'メール送信でエラーが発生する場合' do
      let(:error_message) { 'メール送信エラー' }

      before do
        allow(mail_object).to receive(:deliver_now).and_raise(StandardError.new(error_message))
      end

      it 'Errorを発生させること' do
        expect {
          adapter.deliver_mail(mail_object)
        }.to raise_error(StandardError, /Letter Openerメール送信に失敗: #{Regexp.escape(error_message)}/)
      end

      it 'エラーログが出力されること' do
        expect(Rails.logger).to receive(:error).with(/Letter Openerメール送信中にエラー発生/).at_least(:once)

        expect {
          adapter.deliver_mail(mail_object)
        }.to raise_error(StandardError)
      end
    end
  end

  describe '#configuration_info' do
    let(:expected_info) do
      {
        adapter: "letter_opener",
        name: "Letter Opener",
        environment: Rails.env,
        available: adapter.available?,
        configured: true,
        description: "開発環境専用。メールをブラウザで確認できます。",
        access_url: "http://localhost:3000/letter_opener"
      }
    end

    it '正しい設定情報を返すこと' do
      expect(adapter.configuration_info).to eq(expected_info)
    end
  end

  describe '#adapter_details' do
    it 'configuration_infoと追加の機能情報を含むこと' do
      details = adapter.adapter_details

      expect(details).to include(adapter.configuration_info)
      expect(details[:features]).to eq([
        "開発環境専用",
        "実際のメール送信なし",
        "ブラウザでメール確認",
        "設定不要"
      ])
    end
  end

  describe '#test_connection' do
    before do
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:warn)
    end

    context '開発環境の場合' do
      before do
        allow(Rails.env).to receive(:development?).and_return(true)
      end

      it 'trueを返すこと' do
        expect(adapter.test_connection).to be true
      end

      it '成功ログが出力されること' do
        expect(Rails.logger).to receive(:info).with(/接続テスト開始/)
        expect(Rails.logger).to receive(:info).with(/接続テスト成功: 開発環境で利用可能/)

        adapter.test_connection
      end
    end

    context '本番環境の場合' do
      before do
        allow(Rails.env).to receive(:development?).and_return(false)
      end

      it 'falseを返すこと' do
        expect(adapter.test_connection).to be false
      end

      it '警告ログが出力されること' do
        expect(Rails.logger).to receive(:info).with(/接続テスト開始/)
        expect(Rails.logger).to receive(:warn).with(/接続テスト失敗: Letter Openerは開発環境でのみ利用可能/)

        adapter.test_connection
      end
    end
  end
end
