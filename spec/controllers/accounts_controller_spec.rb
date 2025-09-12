# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountsController, type: :request do
  let(:user) { create(:user) }

  describe 'GET #show' do
    context '認証されている場合' do
      before do
        sign_in user, scope: :user
      end

      it '正常にレスポンスを返すこと' do
        get account_path
        expect(response).to have_http_status(:success)
      end

      it '@userにcurrent_userが設定されること' do
        get account_path
        expect(assigns(:user)).to eq(user)
      end
    end

    context '認証されていない場合' do
      it 'ログインページにリダイレクトされること' do
        get account_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
