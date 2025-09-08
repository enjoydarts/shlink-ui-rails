# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Async Mail', type: :system do
  before do
    driven_by(:rack_test)
  end

  describe 'ユーザー登録時のメール送信' do
    it 'メール確認のジョブがキューイングされること' do
      visit new_user_registration_path

      expect {
        fill_in 'user_email', with: 'test@example.com'
        fill_in 'user_password', with: 'password123'
        fill_in 'user_password_confirmation', with: 'password123'
        click_button 'Sign up'
      }.to have_enqueued_job(DeviseMailerJob)
        .with(:confirmation_instructions, anything, anything, anything)
    end
  end

  describe 'パスワードリセット時のメール送信' do
    let!(:user) { create(:user, confirmed_at: Time.current) }

    it 'パスワードリセットのジョブがキューイングされること' do
      visit new_user_password_path

      expect {
        fill_in 'user_email', with: user.email
        click_button 'Send me reset password instructions'
      }.to have_enqueued_job(DeviseMailerJob)
        .with(:reset_password_instructions, anything, anything, anything)
    end
  end
end