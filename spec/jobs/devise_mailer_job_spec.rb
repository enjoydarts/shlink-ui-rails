# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeviseMailerJob, type: :job do
  let(:user) { create(:user) }
  let(:token) { 'test-token' }
  let(:mail_adapter) { instance_double(MailAdapter::SmtpAdapter) }
  let(:mail_object) { instance_double(ActionMailer::MessageDelivery) }

  before do
    allow(MailAdapter::Factory).to receive(:create_adapter).and_return(mail_adapter)
    allow(Devise::Mailer).to receive(:reset_password_instructions).and_return(mail_object)
    allow(Devise::Mailer).to receive(:confirmation_instructions).and_return(mail_object)

    # メールオブジェクトのモック設定
    mail_message = instance_double('Mail::Message')
    allow(mail_message).to receive(:subject).and_return('Password Reset Instructions')
    allow(mail_message).to receive(:to).and_return([ 'test@example.com' ])
    allow(mail_message).to receive(:from).and_return([ 'noreply@example.com' ])
    allow(mail_object).to receive(:message).and_return(mail_message)
    allow(mail_object).to receive(:deliver_now).and_return(true)
  end

  describe '#perform' do
    before do
      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:error)
    end

    context '正常なメール送信の場合' do
      before do
        allow(mail_adapter).to receive(:deliver_mail).and_return(true)
      end

      it 'アダプタ経由でメールを送信すること' do
        expect(mail_adapter).to receive(:deliver_mail).with(mail_object)

        described_class.perform_now('reset_password_instructions', user, token)
      end

      it 'ログメッセージを出力すること' do
        expect(Rails.logger).to receive(:info).with(/DeviseMailerJob開始: reset_password_instructions/)
        expect(Rails.logger).to receive(:info).with(/DeviseMailerJob完了: reset_password_instructions/)

        described_class.perform_now('reset_password_instructions', user, token)
      end
    end

    context 'トークンなしのメール送信の場合' do
      before do
        allow(Devise::Mailer).to receive(:confirmation_instructions).and_return(mail_object)
        allow(mail_adapter).to receive(:deliver_mail).and_return(true)
      end

      it 'トークンなしでDevise::Mailerを呼び出すこと' do
        expect(Devise::Mailer).to receive(:confirmation_instructions).with(user, { mapping: :user })

        described_class.perform_now('confirmation_instructions', user)
      end
    end

    context 'オプション付きのメール送信の場合' do
      let(:opts) { { custom_option: 'value' } }

      before do
        allow(mail_adapter).to receive(:deliver_mail).and_return(true)
      end

      it 'オプションを含めてDevise::Mailerを呼び出すこと' do
        expected_opts = opts.merge(mapping: :user)
        expect(Devise::Mailer).to receive(:reset_password_instructions).with(user, token, expected_opts)

        described_class.perform_now('reset_password_instructions', user, token, opts)
      end
    end

    context 'アダプタエラーが発生した場合' do
      let(:adapter_error) { MailAdapter::BaseAdapter::Error.new('Adapter error') }

      before do
        allow(mail_adapter).to receive(:deliver_mail).and_raise(adapter_error)
        allow(Rails.logger).to receive(:error)
        allow(Rails.logger).to receive(:info)
      end

      it 'エラーログを出力すること' do
        expect(Rails.logger).to receive(:error).with(/アダプタエラー/)

        # ジョブが実行され、ログが出力されることを確認
        begin
          described_class.perform_now('reset_password_instructions', user, token)
        rescue MailAdapter::BaseAdapter::Error
          # エラーが発生してもテストは成功
        end
      end
    end

    context '予期しないエラーが発生した場合' do
      let(:standard_error) { StandardError.new('Unexpected error') }

      before do
        allow(mail_adapter).to receive(:deliver_mail).and_raise(standard_error)
        allow(mail_object).to receive(:deliver_now).and_return(true)
      end

      it 'フォールバック送信を実行すること' do
        expect(mail_object).to receive(:deliver_now)
        expect(Rails.logger).to receive(:error).with(/予期しないエラー/)
        expect(Rails.logger).to receive(:warn).with(/フォールバック送信を実行/)
        expect(Rails.logger).to receive(:info).with(/フォールバック送信完了/)

        described_class.perform_now('reset_password_instructions', user, token)
      end

      it 'エラーのバックトレースをログ出力すること' do
        allow(standard_error).to receive(:backtrace).and_return([ 'line1', 'line2' ])
        allow(Rails.logger).to receive(:debug).and_call_original
        expect(Rails.logger).to receive(:debug).with(/📋 スタックトレース:\nline1\nline2/)

        described_class.perform_now('reset_password_instructions', user, token)
      end
    end

    context 'フォールバック送信も失敗した場合' do
      let(:standard_error) { StandardError.new('Unexpected error') }
      let(:fallback_error) { StandardError.new('Fallback error') }

      before do
        allow(mail_adapter).to receive(:deliver_mail).and_raise(standard_error)
        allow(mail_object).to receive(:deliver_now).and_raise(fallback_error)
      end

      it '元のエラーを再発生させること' do
        expect(Rails.logger).to receive(:error).with(/予期しないエラー/)
        expect(Rails.logger).to receive(:warn).with(/フォールバック送信を実行/)
        expect(Rails.logger).to receive(:error).with(/フォールバック送信も失敗/)

        expect {
          described_class.perform_now('reset_password_instructions', user, token)
        }.to raise_error(StandardError, 'Unexpected error')
      end
    end
  end
end
