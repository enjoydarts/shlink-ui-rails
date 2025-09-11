require 'rails_helper'

RSpec.describe "Users::OmniauthCallbacks", type: :request do
  describe "GET /users/auth/google_oauth2/callback" do
    let(:auth_hash) do
      OmniAuth::AuthHash.new({
        'provider' => 'google_oauth2',
        'uid' => '123456789',
        'info' => OmniAuth::AuthHash::InfoHash.new({
          'email' => 'test@example.com',
          'name' => 'Test User'
        })
      })
    end

    before do
      OmniAuth.config.test_mode = true
      OmniAuth.config.mock_auth[:google_oauth2] = auth_hash
    end

    after do
      OmniAuth.config.test_mode = false
      OmniAuth.config.mock_auth[:google_oauth2] = nil
    end

    context '新規ユーザーの場合' do
      it 'ユーザーを作成してサインインすること' do
        expect {
          get '/users/auth/google_oauth2/callback'
        }.to change(User, :count).by(1)

        created_user = User.last
        expect(created_user.email).to eq('test@example.com')
        expect(created_user.name).to eq('Test User')
        expect(created_user.provider).to eq('google_oauth2')
        expect(created_user.uid).to eq('123456789')

        expect(response).to redirect_to(dashboard_path)
        follow_redirect!
        expect(response.body).to include('URL短縮ツール')
      end
    end

    context '既存ユーザーの場合' do
      before do
        create(:user, email: 'test@example.com')
      end

      it 'ユーザーを作成せずサインインすること' do
        expect {
          get '/users/auth/google_oauth2/callback'
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
        get '/users/auth/google_oauth2/callback'

        expect(response).to redirect_to(new_user_registration_url)
        follow_redirect!
        expect(flash[:alert]).to eq('Error occurred')
      end
    end
  end
end
