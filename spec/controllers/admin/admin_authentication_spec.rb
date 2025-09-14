require 'rails_helper'

RSpec.describe 'Admin Authentication', type: :request do
  let(:admin_user) { create(:user, role: :admin) }
  let(:normal_user) { create(:user, role: :normal_user) }

  before do
    # Settings gemのモック設定（Admin::ServerMonitorService用）
    if defined?(Settings)
      allow(Settings).to receive_message_chain(:shlink, :base_url).and_return("https://test.example.com")
      allow(Settings).to receive_message_chain(:shlink, :api_key).and_return("test-api-key")
    end
  end

  describe 'admin routes authentication' do
    context 'when not authenticated' do
      it 'redirects admin dashboard to login' do
        get '/admin'
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects admin users to login' do
        get '/admin/users'
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects admin settings to login' do
        get '/admin/settings'
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects admin jobs to login' do
        get '/admin/jobs'
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when authenticated as normal user' do
      before { sign_in normal_user, scope: :user }

      it 'redirects to root with access denied message for admin dashboard' do
        get '/admin'
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('管理者権限が必要です。')
      end

      it 'redirects to root with access denied message for admin users' do
        get '/admin/users'
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq('管理者権限が必要です。')
      end
    end

    context 'when authenticated as admin user' do
      before { sign_in admin_user, scope: :user }

      it 'allows access to admin dashboard' do
        get '/admin'
        expect(response).to have_http_status(:success)
      end

      it 'allows access to admin users' do
        get '/admin/users'
        expect(response).to have_http_status(:success)
      end

      it 'allows access to admin settings' do
        get '/admin/settings'
        expect(response).to have_http_status(:success)
      end

      it 'allows access to admin jobs' do
        get '/admin/jobs'
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'after_sign_in_path_for' do
    it 'redirects admin to admin dashboard after login' do
      post '/users/sign_in', params: {
        user: {
          email: admin_user.email,
          password: 'Password123!'
        }
      }
      expect(response).to redirect_to(admin_dashboard_path)
    end

    it 'redirects normal user to dashboard after login' do
      post '/users/sign_in', params: {
        user: {
          email: normal_user.email,
          password: 'Password123!'
        }
      }
      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe 'old admin login routes' do
    it 'returns 404 for old admin login page' do
      get '/admin/login'
      expect(response).to have_http_status(:not_found)
    rescue ActionController::RoutingError
      # This is the expected behavior - route doesn't exist
      expect(true).to be_truthy
    end
  end
end
