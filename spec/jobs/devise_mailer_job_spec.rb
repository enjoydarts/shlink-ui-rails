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
  end

  describe '#perform' do
    context '正常なメール送信の場合' do
      before do
        allow(mail_adapter).to receive(:deliver_mail).and_return(true)
      end

      it 'アダプタ経由でメールを送信すること' do
        expect(mail_adapter).to receive(:deliver_mail).with(mail_object)

        described_class.perform_now('reset_password_instructions', user, token)
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
        described_class.perform_now('reset_password_instructions', user, token)
      end
    end
  end
end
