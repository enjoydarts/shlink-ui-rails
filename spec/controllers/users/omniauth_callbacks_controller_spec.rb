# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :request do
  describe 'POST #google_oauth2' do
    let(:oauth_auth) do
      {
        'provider' => 'google_oauth2',
        'uid' => '123456789',
        'info' => {
          'email' => 'test@example.com',
          'name' => 'Test User'
        },
        'credentials' => {
          'token' => 'mock_token'
        }
      }
    end

    before do
      Rails.application.env_config["omniauth.auth"] = oauth_auth
    end

    context 'ユーザーが正常に作成/取得できる場合' do
      let(:user) { create(:user, :from_oauth, email: 'test@example.com') }

      before do
        allow(User).to receive(:from_omniauth).and_return(user)
      end

      it 'ユーザーをサインインしてリダイレクトすること' do
        post "/users/auth/google_oauth2/callback"
        
        expect(response).to redirect_to(root_path)
      end
    end

    context 'ユーザーの作成に失敗した場合' do
      let(:user) { build(:user, :from_oauth) }

      before do
        user.errors.add(:email, 'is invalid')
        allow(User).to receive(:from_omniauth).and_return(user)
      end

      xit '新規登録ページにリダイレクトすること' do
        post "/users/auth/google_oauth2/callback"
        
        expect(response).to redirect_to(new_user_registration_url)
      end
    end
  end

  describe 'failureメソッド' do
    it 'failureメソッドが定義されていること' do
      expect(described_class.instance_methods).to include(:failure)
    end
  end
end