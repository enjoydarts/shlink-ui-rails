require 'rails_helper'

RSpec.describe Admin::SessionsController, type: :controller do
  describe 'GET #new' do
    context '管理者でログインしていない場合' do
      it 'ログインページを表示すること' do
        get :new
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:new)
      end
    end

    context '管理者でログイン済みの場合' do
      let(:admin) { create(:user, role: 'admin') }

      before do
        sign_in admin
      end

      it '管理者ダッシュボードにリダイレクトすること' do
        get :new
        expect(response).to redirect_to(admin_dashboard_path)
      end
    end
  end

  describe 'POST #create' do
    let(:admin) { create(:user, email: 'admin@example.com', password: 'password', role: 'admin') }
    let(:normal_user) { create(:user, email: 'user@example.com', password: 'password', role: 'normal_user') }

    context '有効な管理者の認証情報の場合' do
      it 'ログインして管理者ダッシュボードにリダイレクトすること' do
        post :create, params: { email: admin.email, password: 'password' }
        expect(response).to redirect_to(admin_dashboard_path)
        expect(flash[:notice]).to eq('管理者としてログインしました。')
        expect(controller.current_user).to eq(admin)
      end
    end

    context '有効な一般ユーザーの認証情報の場合' do
      it 'ログインを拒否すること' do
        post :create, params: { email: normal_user.email, password: 'password' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:new)
        expect(flash[:alert]).to eq('管理者権限が必要です。')
        expect(controller.current_user).to be_nil
      end
    end

    context '無効な認証情報の場合' do
      it 'ログインを拒否すること' do
        post :create, params: { email: admin.email, password: 'wrong_password' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:new)
        expect(flash[:alert]).to eq('メールアドレスまたはパスワードが正しくありません。')
        expect(controller.current_user).to be_nil
      end
    end

    context '存在しないユーザーの場合' do
      it 'ログインを拒否すること' do
        post :create, params: { email: 'nonexistent@example.com', password: 'password' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:new)
        expect(flash[:alert]).to eq('メールアドレスまたはパスワードが正しくありません。')
        expect(controller.current_user).to be_nil
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:admin) { create(:user, role: 'admin') }

    context 'ログイン中の場合' do
      before do
        sign_in admin
      end

      it 'ログアウトして管理者ログインページにリダイレクトすること' do
        delete :destroy
        expect(response).to redirect_to(admin_login_path)
        expect(flash[:notice]).to eq('ログアウトしました。')
        expect(controller.current_user).to be_nil
      end
    end

    context 'ログインしていない場合' do
      it 'エラーなく管理者ログインページにリダイレクトすること' do
        delete :destroy
        expect(response).to redirect_to(admin_login_path)
        expect(flash[:notice]).to eq('ログアウトしました。')
      end
    end
  end
end
