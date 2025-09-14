require 'rails_helper'

RSpec.describe Admin::AdminController, type: :controller do
  controller do
    def index
      render plain: 'test'
    end
  end

  describe '管理者認証' do
    context 'ログインしていない場合' do
      it 'ユーザーログインページにリダイレクトすること' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context '一般ユーザーでログインしている場合' do
      let(:user) { create(:user, role: 'normal_user') }

      before do
        sign_in user, scope: :user
      end

      it 'ルートページにリダイレクトすること' do
        get :index
        expect(response).to redirect_to(root_path)
      end

      it '管理者権限エラーメッセージが表示されること' do
        get :index
        expect(flash[:alert]).to eq('管理者権限が必要です。')
      end
    end

    context '管理者でログインしている場合' do
      let(:admin) { create(:user, role: 'admin') }

      before do
        sign_in admin, scope: :user
      end

      it 'アクセスが許可されること' do
        get :index
        expect(response).to have_http_status(:success)
      end
    end
  end
end
