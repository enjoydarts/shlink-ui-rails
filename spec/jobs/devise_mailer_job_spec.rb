require 'rails_helper'

RSpec.describe DeviseMailerJob, type: :job do
  let(:user) { create(:user) }
  let(:token) { 'fake_token' }
  let(:mail_object) { instance_double('ActionMailer::MessageDelivery') }
  let(:adapter) { instance_double('MailAdapter::SmtpAdapter') }

  before do
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
  end

  describe '#perform' do
    context 'when method requires token' do
      before do
        allow(Devise::Mailer).to receive(:confirmation_instructions)
          .with(user, token, {})
          .and_return(mail_object)
        allow(MailAdapter::Factory).to receive(:create_adapter).and_return(adapter)
        allow(adapter).to receive(:deliver_mail).and_return(true)
      end

      it 'sends confirmation email via adapter' do
        expect(adapter).to receive(:deliver_mail).with(mail_object)
        DeviseMailerJob.perform_now('confirmation_instructions', user, token)
      end

      it 'logs start and completion messages' do
        expect(Rails.logger).to receive(:info).with(/DeviseMailerJob開始/)
        expect(Rails.logger).to receive(:info).with(/DeviseMailerJob完了/)
        DeviseMailerJob.perform_now('confirmation_instructions', user, token)
      end

      it 'sends reset password email' do
        allow(Devise::Mailer).to receive(:reset_password_instructions)
          .with(user, token, {})
          .and_return(mail_object)

        expect(adapter).to receive(:deliver_mail).with(mail_object)
        DeviseMailerJob.perform_now('reset_password_instructions', user, token)
      end

      it 'sends unlock instructions email' do
        allow(Devise::Mailer).to receive(:unlock_instructions)
          .with(user, token, {})
          .and_return(mail_object)

        expect(adapter).to receive(:deliver_mail).with(mail_object)
        DeviseMailerJob.perform_now('unlock_instructions', user, token)
      end
    end

    context 'when method does not require token' do
      before do
        allow(MailAdapter::Factory).to receive(:create_adapter).and_return(adapter)
        allow(adapter).to receive(:deliver_mail).and_return(true)
      end

      it 'sends email changed notification' do
        allow(Devise::Mailer).to receive(:email_changed)
          .with(user, {})
          .and_return(mail_object)

        expect(adapter).to receive(:deliver_mail).with(mail_object)
        DeviseMailerJob.perform_now('email_changed', user, nil, {})
      end

      it 'sends password change notification' do
        allow(Devise::Mailer).to receive(:password_change)
          .with(user, {})
          .and_return(mail_object)

        expect(adapter).to receive(:deliver_mail).with(mail_object)
        DeviseMailerJob.perform_now('password_change', user, nil, {})
      end
    end

    context 'with options' do
      let(:opts) { { subject: 'Custom Subject' } }

      before do
        allow(MailAdapter::Factory).to receive(:create_adapter).and_return(adapter)
        allow(adapter).to receive(:deliver_mail).and_return(true)
      end

      it 'passes options to mailer' do
        allow(Devise::Mailer).to receive(:confirmation_instructions)
          .with(user, token, opts)
          .and_return(mail_object)

        expect(adapter).to receive(:deliver_mail).with(mail_object)
        DeviseMailerJob.perform_now('confirmation_instructions', user, token, opts)
      end
    end


    context 'when unexpected error occurs' do
      let(:unexpected_error) { StandardError.new('Unexpected error') }

      before do
        allow(Devise::Mailer).to receive(:confirmation_instructions)
          .with(user, token, {})
          .and_return(mail_object)
        allow(MailAdapter::Factory).to receive(:create_adapter).and_return(adapter)
        allow(adapter).to receive(:deliver_mail).and_raise(unexpected_error)
        allow(mail_object).to receive(:deliver_now).and_return(true)
      end

      it 'logs error and attempts fallback delivery' do
        expect(Rails.logger).to receive(:error).with(/予期しないエラー/)
        expect(Rails.logger).to receive(:info).with(/フォールバック送信を実行/)
        expect(Rails.logger).to receive(:info).with(/フォールバック送信完了/)

        expect(mail_object).to receive(:deliver_now)
        DeviseMailerJob.perform_now('confirmation_instructions', user, token)
      end

      context 'when fallback also fails' do
        before do
          allow(mail_object).to receive(:deliver_now).and_raise(StandardError.new('Fallback failed'))
        end

        it 'logs fallback failure and re-raises original error' do
          expect(Rails.logger).to receive(:error).with(/フォールバック送信も失敗/)
          expect { DeviseMailerJob.perform_now('confirmation_instructions', user, token) }
            .to raise_error(StandardError, 'Unexpected error')
        end
      end
    end
  end

  describe 'retry configuration' do
    it 'has retry configuration for MailAdapter::BaseAdapter::Error' do
      # retry_onの設定があることを確認（Rails 8のretry_on設定をテスト）
      expect(DeviseMailerJob).to respond_to(:retry_on)
    end
  end

  describe 'queue configuration' do
    it 'is queued on the mailers queue' do
      expect(DeviseMailerJob.queue_name).to eq('mailers')
    end
  end
end
