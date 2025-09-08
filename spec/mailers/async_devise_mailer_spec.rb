require 'rails_helper'

RSpec.describe AsyncDeviseMailer, type: :mailer do
  let(:user) { create(:user) }
  let(:token) { 'fake_token' }

  describe '#confirmation_instructions' do
    it 'enqueues DeviseMailerJob with correct parameters' do
      expect(DeviseMailerJob).to receive(:perform_later)
        .with(:confirmation_instructions, user, token, {})

      AsyncDeviseMailer.confirmation_instructions(user, token)
    end

    it 'enqueues job with options' do
      opts = { subject: 'Custom Subject' }
      expect(DeviseMailerJob).to receive(:perform_later)
        .with(:confirmation_instructions, user, token, opts)

      AsyncDeviseMailer.confirmation_instructions(user, token, opts)
    end
  end

  describe '#reset_password_instructions' do
    it 'enqueues DeviseMailerJob with correct parameters' do
      expect(DeviseMailerJob).to receive(:perform_later)
        .with(:reset_password_instructions, user, token, {})

      AsyncDeviseMailer.reset_password_instructions(user, token)
    end
  end

  describe '#unlock_instructions' do
    it 'enqueues DeviseMailerJob with correct parameters' do
      expect(DeviseMailerJob).to receive(:perform_later)
        .with(:unlock_instructions, user, token, {})

      AsyncDeviseMailer.unlock_instructions(user, token)
    end
  end

  describe '#email_changed' do
    it 'enqueues DeviseMailerJob without token' do
      expect(DeviseMailerJob).to receive(:perform_later)
        .with(:email_changed, user, nil, {})

      AsyncDeviseMailer.email_changed(user)
    end
  end

  describe '#password_change' do
    it 'enqueues DeviseMailerJob without token' do
      expect(DeviseMailerJob).to receive(:perform_later)
        .with(:password_change, user, nil, {})

      AsyncDeviseMailer.password_change(user)
    end
  end
end