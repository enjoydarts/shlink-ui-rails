# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Async Mail', type: :system do
  include ActiveJob::TestHelper
  before do
    driven_by(:rack_test)
  end

  describe 'ユーザー登録時のメール送信' do
    it 'メール確認のジョブがキューイングされること' do
      # CAPTCHA検証をスタブ化
      allow(CaptchaVerificationService).to receive(:verify).and_return(
        double(success?: true, error_codes: [])
      )

      visit new_user_registration_path

      expect {
        fill_in 'user_email', with: 'test@example.com'
        fill_in 'user_password', with: 'Password123!'
        fill_in 'user_password_confirmation', with: 'Password123!'
        # 利用規約・プライバシーポリシーの同意チェックボックスをチェック
        check 'terms_agreement'
        check 'privacy_agreement'
        click_button '🚀 新規登録'
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
        click_button '🔄 パスワードリセット送信'
      }.to have_enqueued_job(DeviseMailerJob)
        .with(:reset_password_instructions, anything, anything, anything)
    end
  end
end
