require 'rails_helper'

RSpec.describe Admin::AdminController, type: :controller do
  controller do
    def index
      render plain: 'test'
    end
  end

  describe '管理者認証' do
    context 'ログインしていない場合' do
      it '管理者ログインページにリダイレクトすること' do
        get :index
        expect(response).to redirect_to(admin_login_path)
      end
    end

    context '一般ユーザーでログインしている場合' do
      let(:user) { create(:user, role: 'normal_user') }

      before do
        sign_in user
      end

      it '管理者ログインページにリダイレクトすること' do
        get :index
        expect(response).to redirect_to(admin_login_path)
      end
    end

    context '管理者でログインしている場合' do
      let(:admin) { create(:user, role: 'admin') }

      before do
        sign_in admin
      end

      it 'アクセスが許可されること' do
        get :index
        expect(response).to have_http_status(:success)
      end
    end
  end
end
