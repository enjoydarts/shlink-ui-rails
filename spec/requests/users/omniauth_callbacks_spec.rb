require 'rails_helper'

RSpec.describe "Users::OmniauthCallbacks", type: :request do
  describe "GET /users/auth/google_oauth2/callback" do
    let(:auth_hash) do
      OmniAuth::AuthHash.new({
        'provider' => 'google_oauth2',
        'uid' => '123456789',
        'info' => OmniAuth::AuthHash::InfoHash.new({
          'email' => 'newuser@example.com',
          'name' => 'Test User'
        })
      })
    end

    before do
      OmniAuth.config.test_mode = true

      # SystemSetting基本モック設定
      allow(SystemSetting).to receive(:get).and_call_original
      allow(SystemSetting).to receive(:get).with("shlink.base_url", nil).and_return("https://test.example.com")
      allow(SystemSetting).to receive(:get).with("shlink.api_key", nil).and_return("test-api-key")
      allow(SystemSetting).to receive(:get).with("performance.items_per_page", 20).and_return(20)
      allow(SystemSetting).to receive(:get).with('system.maintenance_mode', false).and_return(false)

      # ApplicationConfig基本モック設定
      allow(ApplicationConfig).to receive(:string).and_call_original
      allow(ApplicationConfig).to receive(:string).with('shlink.base_url', anything).and_return("https://test.example.com")
      allow(ApplicationConfig).to receive(:string).with('shlink.api_key', anything).and_return("test-api-key")
      allow(ApplicationConfig).to receive(:string).with('redis.url', anything).and_return("redis://redis:6379/0")
      allow(ApplicationConfig).to receive(:number).and_call_original
      allow(ApplicationConfig).to receive(:number).with('shlink.timeout', anything).and_return(30)
      allow(ApplicationConfig).to receive(:number).with('redis.timeout', anything).and_return(5)
    end

    after do
      OmniAuth.config.test_mode = false
    end

    context '新規ユーザーの場合' do
      let(:new_user) do
        create(:user, email: 'newuser@example.com', name: 'Test User', provider: 'google_oauth2', uid: '123456789')
      end

      xit 'ユーザーを作成してサインインすること' do
        # 新しいユーザーの作成をモック
        allow(User).to receive(:from_omniauth).with(any_args).and_return(new_user)

        expect {
          get '/users/auth/google_oauth2/callback', env: { "omniauth.auth" => auth_hash }
        }.to change(User, :count).by(1)

        expect(response).to redirect_to(dashboard_path)
        follow_redirect!
        expect(response.body).to include('URL短縮ツール')
      end
    end

    context '既存ユーザーの場合' do
      let!(:existing_user) do
        create(:user, email: 'existing@example.com', name: 'Existing User', provider: 'google_oauth2', uid: '987654321')
      end

      let(:existing_user_auth_hash) do
        OmniAuth::AuthHash.new({
          'provider' => 'google_oauth2',
          'uid' => '987654321',
          'info' => OmniAuth::AuthHash::InfoHash.new({
            'email' => 'existing@example.com',
            'name' => 'Existing User'
          })
        })
      end

      xit 'ユーザーを作成せずサインインすること' do
        # User.from_omniauthを直接モック
        allow(User).to receive(:from_omniauth).with(any_args).and_return(existing_user)

        expect {
          get '/users/auth/google_oauth2/callback', env: { "omniauth.auth" => existing_user_auth_hash }
        }.not_to change(User, :count)

        expect(response).to redirect_to(dashboard_path)
        follow_redirect!
        expect(response.body).to include('URL短縮ツール')
      end
    end

    context 'ユーザー作成に失敗した場合' do
      before do
        allow(User).to receive(:from_omniauth).and_return(
          double(persisted?: false, errors: double(full_messages: [ 'Error occurred' ]))
        )
      end

      it '登録ページにリダイレクトすること' do
        get '/users/auth/google_oauth2/callback', env: { "omniauth.auth" => auth_hash }

        expect(response).to redirect_to(new_user_registration_url)
        follow_redirect!
        expect(flash[:alert]).to eq('Error occurred')
      end
    end
  end
end
