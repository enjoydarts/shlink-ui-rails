# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Users::WebauthnCredentialsController, type: :request do
  let(:user) { create(:user) }
  let(:oauth_user) { create(:user, :from_oauth, provider: 'google_oauth2') }

  describe 'GET #registration_options' do
    before do
      sign_in user, scope: :user
      # webauthn_idを正しいフォーマットでモック
      allow(user).to receive(:webauthn_id).and_return('test_webauthn_id')
    end

    context '正常な場合' do
      it 'WebAuthn登録オプションをJSONで返すこと' do
        mock_options = {
          'challenge' => 'test_challenge',
          'user' => {
            'id' => 'user_123',
            'name' => user.email,
            'displayName' => user.email
          },
          'rp' => { 'id' => 'localhost', 'name' => 'Test App' },
          'pubKeyCredParams' => [],
          'timeout' => 60000
        }
        allow(WebauthnService).to receive(:registration_options).with(user).and_return(mock_options)

        get registration_options_users_webauthn_credentials_path

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')
        json_response = JSON.parse(response.body)
        expect(json_response).to eq(mock_options)
        expect(session[:webauthn_registration_challenge]).to eq('test_challenge')
      end
    end

    context 'エラーが発生した場合' do
      before do
        allow(WebauthnService).to receive(:registration_options).and_raise(StandardError, 'Test error')
      end

      xit 'エラーレスポンスを返すこと' do
        get registration_options_users_webauthn_credentials_path

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq("セキュリティキーの登録準備に失敗しました")
      end
    end
  end

  describe 'GET #authentication_options' do
    context '通常ユーザーの場合' do
      before do
        sign_in user, scope: :user
        allow(user).to receive(:webauthn_enabled?).and_return(true)
      end

      it 'WebAuthn認証オプションをJSONで返すこと' do
        mock_options = {
          challenge: 'auth_challenge',
          allowCredentials: [],
          timeout: 60000,
          userVerification: 'preferred'
        }
        allow(WebauthnService).to receive(:authentication_options).with(user).and_return(mock_options)

        get authentication_options_users_webauthn_credentials_path

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response).to eq(mock_options.stringify_keys)
      end
    end


    context 'login_optionsアクションの場合' do
      let(:webauthn_user) { create(:user, email: 'webauthn@example.com') }

      before do
        allow(User).to receive(:find_by).with(email: 'webauthn@example.com').and_return(webauthn_user)
        allow(webauthn_user).to receive(:webauthn_enabled?).and_return(true)
      end

      it '認証なしでアクセスできること' do
        mock_options = {
          challenge: 'login_challenge',
          allowCredentials: [],
          timeout: 60000,
          userVerification: 'preferred'
        }
        allow(WebauthnService).to receive(:authentication_options).with(webauthn_user).and_return(mock_options)

        get login_options_users_webauthn_credentials_path, params: { email: 'webauthn@example.com' }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response).to eq(mock_options.stringify_keys)
      end
    end

    context '認証されていない場合' do
      it 'ログインページにリダイレクトされること' do
        get authentication_options_users_webauthn_credentials_path

        expect(response).to have_http_status(:unprocessable_content).or have_http_status(:found)
        if response.status == 302
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context 'WebAuthnが無効なユーザーの場合' do
      before do
        sign_in user, scope: :user
        allow(user).to receive(:webauthn_enabled?).and_return(false)
      end

      xit 'エラーレスポンスを返すこと' do
        get authentication_options_users_webauthn_credentials_path

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('セキュリティキーが登録されていません')
      end
    end
  end

  describe 'POST #create' do
    before do
      sign_in user, scope: :user
    end

    let(:valid_params) do
      {
        credential: '{"id":"test_credential","response":{"attestationObject":"test_attestation"}}',
        nickname: 'Test Key'
      }
    end

    context '有効なクレデンシャルの場合' do
      let(:mock_credential) { double('credential', id: 'test_id', nickname: 'Test Key') }

      before do
        allow(WebauthnService).to receive(:register_credential).and_return(mock_credential)
        allow(mock_credential).to receive(:display_info).and_return({ id: 'test_id', nickname: 'Test Key' })
      end

      xit 'クレデンシャルを登録してJSONで返すこと' do
        # セッションにチャレンジを設定
        get registration_options_users_webauthn_credentials_path

        post users_webauthn_credentials_path, params: valid_params

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['message']).to eq('セキュリティキーを登録しました')
        expect(json_response['credential']).to eq({ 'id' => 'test_id', 'nickname' => 'Test Key' })
      end
    end

    context '無効なクレデンシャルの場合' do
      before do
        allow(WebauthnService).to receive(:register_credential).and_raise(StandardError, 'Registration failed')
      end

      xit 'エラーレスポンスを返すこと' do
        # セッションにチャレンジを設定
        get registration_options_users_webauthn_credentials_path

        post users_webauthn_credentials_path, params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Registration failed')
      end
    end

    context '無効なJSONパラメータの場合' do
      xit 'エラーレスポンスを返すこと' do
        # セッションにチャレンジを設定
        get registration_options_users_webauthn_credentials_path

        post users_webauthn_credentials_path, params: { credential: 'invalid_json', nickname: 'Test Key' }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('無効なデータ形式です')
      end
    end

    context 'セッションチャレンジがない場合' do
      it 'セッション無効エラーを返すこと' do
        post users_webauthn_credentials_path, params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('セッションが無効です。再度お試しください')
      end
    end
  end

  describe 'PATCH #update' do
    before do
      sign_in user, scope: :user
    end

    let(:mock_credential) do
      double('credential',
        update: true,
        display_info: { id: 1, nickname: 'Updated Key' }
      )
    end

    context '有効なパラメータの場合' do
      before do
        allow(user.webauthn_credentials).to receive(:find).with('1').and_return(mock_credential)
      end

      it 'クレデンシャルの名前を更新すること' do
        patch users_webauthn_credential_path(1), params: { nickname: 'Updated Key' }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['message']).to eq('セキュリティキーの名前を変更しました')
      end
    end

    context '更新に失敗した場合' do
      before do
        allow(user.webauthn_credentials).to receive(:find).with('1').and_return(mock_credential)
        allow(mock_credential).to receive(:update).and_return(false)
        allow(mock_credential).to receive(:errors).and_return(double('errors', full_messages: [ 'Nickname is invalid' ]))
      end

      xit 'エラーレスポンスを返すこと' do
        patch users_webauthn_credential_path(1), params: { nickname: '' }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['errors']).to eq([ 'Nickname is invalid' ])
      end
    end

    context '存在しないクレデンシャルの場合' do
      before do
        allow(user.webauthn_credentials).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      end

      xit 'エラーレスポンスを返すこと' do
        patch users_webauthn_credential_path(999), params: { nickname: 'Test' }

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('セキュリティキーが見つかりません')
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      sign_in user, scope: :user
    end

    context '削除に成功した場合' do
      before do
        allow(WebauthnService).to receive(:remove_credential).with(user, '1').and_return(true)
      end

      it 'クレデンシャルを削除してJSONで返すこと' do
        delete users_webauthn_credential_path(1), headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['message']).to eq('セキュリティキーを削除しました')
      end

      context 'HTMLリクエストの場合' do
        it 'アカウント画面にリダイレクトすること' do
          delete users_webauthn_credential_path(1), headers: { 'Accept' => 'text/html' }

          expect(response).to redirect_to(account_path)
          expect(flash[:notice]).to eq('セキュリティキーを削除しました')
        end
      end
    end

    context '削除に失敗した場合' do
      before do
        allow(WebauthnService).to receive(:remove_credential).with(user, '1').and_return(false)
      end

      xit 'エラーレスポンスを返すこと' do
        delete users_webauthn_credential_path(1), headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['message']).to eq('セキュリティキーの削除に失敗しました')
      end
    end

    context 'エラーが発生した場合' do
      before do
        allow(WebauthnService).to receive(:remove_credential).and_raise(StandardError, 'Delete error')
      end

      xit 'エラーレスポンスを返すこと' do
        delete users_webauthn_credential_path(1), headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['message']).to eq('セキュリティキーの削除に失敗しました')
      end
    end
  end
end
