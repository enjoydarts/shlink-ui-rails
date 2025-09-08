require 'rails_helper'

RSpec.describe DeviseMailerJob, type: :job do
  let(:user) { create(:user) }
  let(:token) { 'fake_token' }

  describe '#perform' do
    context 'when method requires token' do
      it 'sends confirmation email' do
        expect(Devise::Mailer).to receive(:confirmation_instructions)
          .with(user, token, {})
          .and_return(double(deliver_now: true))

        DeviseMailerJob.perform_now('confirmation_instructions', user, token)
      end

      it 'sends reset password email' do
        expect(Devise::Mailer).to receive(:reset_password_instructions)
          .with(user, token, {})
          .and_return(double(deliver_now: true))

        DeviseMailerJob.perform_now('reset_password_instructions', user, token)
      end

      it 'sends unlock instructions email' do
        expect(Devise::Mailer).to receive(:unlock_instructions)
          .with(user, token, {})
          .and_return(double(deliver_now: true))

        DeviseMailerJob.perform_now('unlock_instructions', user, token)
      end
    end

    context 'when method does not require token' do
      it 'sends email changed notification' do
        expect(Devise::Mailer).to receive(:email_changed)
          .with(user, {})
          .and_return(double(deliver_now: true))

        DeviseMailerJob.perform_now('email_changed', user, nil, {})
      end

      it 'sends password change notification' do
        expect(Devise::Mailer).to receive(:password_change)
          .with(user, {})
          .and_return(double(deliver_now: true))

        DeviseMailerJob.perform_now('password_change', user, nil, {})
      end
    end

    context 'with options' do
      let(:opts) { { subject: 'Custom Subject' } }

      it 'passes options to mailer' do
        expect(Devise::Mailer).to receive(:confirmation_instructions)
          .with(user, token, opts)
          .and_return(double(deliver_now: true))

        DeviseMailerJob.perform_now('confirmation_instructions', user, token, opts)
      end
    end
  end

  describe 'queue configuration' do
    it 'is queued on the mailers queue' do
      expect(DeviseMailerJob.queue_name).to eq('mailers')
    end
  end
end