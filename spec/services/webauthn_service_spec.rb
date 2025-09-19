# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebauthnService, type: :service do
  let(:user) { create(:user) }

  before do
    # WebAuthn origin設定をモック
    allow(Rails.application.config).to receive(:webauthn_origin).and_return('http://localhost:3000')
  end

  describe '.registration_options' do
    it 'WebAuthn登録用オプションを生成すること' do
      allow(user).to receive(:webauthn_id).and_return('test_user_id')
      allow(user).to receive(:display_name).and_return('Test User')
      allow(user.webauthn_credentials).to receive(:active).and_return([])

      mock_options = {
        'challenge' => 'test_challenge',
        'user' => { 'id' => 'test_user_id' },
        'excludeCredentials' => []
      }
      allow(WebAuthn::Credential).to receive(:options_for_create).and_return(mock_options)

      result = described_class.registration_options(user)

      expect(result).to eq(mock_options)
      expect(WebAuthn::Credential).to have_received(:options_for_create)
    end
  end

  describe '.authentication_options' do
    it 'WebAuthn認証用オプションを生成すること' do
      credential = create(:webauthn_credential, user: user)
      allow(user.webauthn_credentials).to receive(:active).and_return([ credential ])

      mock_options = {
        'challenge' => 'test_challenge',
        'allowCredentials' => []
      }
      allow(WebAuthn::Credential).to receive(:options_for_get).and_return(mock_options)

      result = described_class.authentication_options(user)

      expected_result = mock_options.merge('rpId' => 'localhost')
      expect(result).to eq(expected_result)
      expect(WebAuthn::Credential).to have_received(:options_for_get)
    end
  end

  describe '.register_credential' do
    let(:mock_credential_response) do
      {
        'type' => 'webauthn.create',
        'id' => 'test_credential_id',
        'response' => {
          'attestationObject' => 'test_attestation',
          'clientDataJSON' => 'test_client_data'
        }
      }
    end
    let(:challenge) { 'test_challenge' }
    let(:nickname) { 'Test Key' }

    before do
      # WebAuthn検証の成功をモック
      mock_webauthn_cred = double('webauthn_cred',
        id: 'test_credential_id',
        public_key: 'test_public_key',
        sign_count: 0
      )
      allow(WebAuthn::Credential).to receive(:from_create).and_return(mock_webauthn_cred)
      allow(mock_webauthn_cred).to receive(:verify).and_return(true)

      # DBレコード作成をモック
      allow(user.webauthn_credentials).to receive(:create!).and_return(
        double('webauthn_credential', id: 1, nickname: nickname, display_info: { id: 1, nickname: nickname })
      )
    end

    it 'WebAuthnクレデンシャルを登録すること' do
      result = described_class.register_credential(user, mock_credential_response, challenge, nickname: nickname)

      expect(result).not_to be_nil
      expect(user.webauthn_credentials).to have_received(:create!)
    end
  end

  describe '.verify_authentication' do
    let(:mock_credential_response) { { 'id' => 'test_cred_id', 'response' => {} } }
    let(:challenge) { 'test_challenge' }

    context '無効なクレデンシャルの場合' do
      before do
        # activeスコープをモック
        active_scope = double('active_scope')
        allow(user.webauthn_credentials).to receive(:active).and_return(active_scope)
        allow(active_scope).to receive(:find_by).and_return(nil)
      end

      it 'falseを返すこと' do
        result = described_class.verify_authentication(user, mock_credential_response, challenge)
        expect(result).to be false
      end
    end

    context '有効なクレデンシャルの場合' do
      before do
        # データベースのクレデンシャルをモック
        mock_stored_credential = double('stored_credential',
          external_id: 'test_cred_id',
          public_key: 'public_key_data',
          sign_count: 0
        )
        allow(mock_stored_credential).to receive(:update!)

        # activeスコープをモック
        active_scope = double('active_scope')
        allow(user.webauthn_credentials).to receive(:active).and_return(active_scope)
        allow(active_scope).to receive(:find_by).and_return(mock_stored_credential)

        # WebAuthn検証をモック
        mock_webauthn_credential = double('webauthn_credential')
        allow(WebAuthn::Credential).to receive(:from_get).and_return(mock_webauthn_credential)
        allow(mock_webauthn_credential).to receive(:verify).and_return(true)
        allow(mock_webauthn_credential).to receive(:sign_count).and_return(1)
      end

      it 'trueを返すこと' do
        result = described_class.verify_authentication(user, mock_credential_response, challenge)
        expect(result).to be true
      end
    end
  end

  describe '.remove_credential' do
    context 'クレデンシャルが存在しない場合' do
      before do
        allow(user.webauthn_credentials).to receive(:find).and_raise(ActiveRecord::RecordNotFound)
      end

      it 'falseを返すこと' do
        result = described_class.remove_credential(user, 'non_existent_id')
        expect(result).to be false
      end
    end

    context 'クレデンシャルが存在する場合' do
      let(:mock_credential) { double('credential') }

      before do
        allow(user.webauthn_credentials).to receive(:find).with('1').and_return(mock_credential)
        allow(mock_credential).to receive(:destroy!).and_return(true)
      end

      it 'クレデンシャルを削除してtrueを返すこと' do
        result = described_class.remove_credential(user, '1')

        expect(result).to be true
        expect(mock_credential).to have_received(:destroy!)
      end
    end
  end
end
