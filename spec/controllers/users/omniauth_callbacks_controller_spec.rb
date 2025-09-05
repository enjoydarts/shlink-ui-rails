require 'rails_helper'

RSpec.describe Users::OmniauthCallbacksController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe 'GET #google_oauth2' do
    let(:auth_hash) do
      {
        'provider' => 'google_oauth2',
        'uid' => '123456789',
        'info' => {
          'email' => 'test@example.com',
          'name' => 'Test User'
        }
      }
    end

    before do
      @request.env["omniauth.auth"] = auth_hash
    end

    context '新規ユーザーの場合' do
      it 'ユーザーを作成してサインインすること' do
        expect {
          get :google_oauth2
        }.to change(User, :count).by(1)

        created_user = User.last
        expect(created_user.email).to eq('test@example.com')
        expect(created_user.name).to eq('Test User')
        expect(created_user.provider).to eq('google_oauth2')
        expect(created_user.uid).to eq('123456789')

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include('Google')
      end
    end

    context '既存ユーザーの場合' do
      before do
        create(:user, email: 'test@example.com')
      end

      it 'ユーザーを作成せずサインインすること' do
        expect {
          get :google_oauth2
        }.not_to change(User, :count)

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include('Google')
      end
    end

    context 'ユーザー作成に失敗した場合' do
      before do
        allow(User).to receive(:from_omniauth).and_return(
          double(persisted?: false, errors: double(full_messages: ['Error occurred']))
        )
      end

      it '登録ページにリダイレクトすること' do
        get :google_oauth2

        expect(response).to redirect_to(new_user_registration_url)
        expect(flash[:alert]).to eq('Error occurred')
      end
    end
  end

  describe 'GET #failure' do
    it 'ルートページにリダイレクトすること' do
      get :failure

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('Googleアカウントでのログインに失敗しました。')
    end
  end
end