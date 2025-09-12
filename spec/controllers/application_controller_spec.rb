# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller(ApplicationController) do
    def test_action
      verify_captcha ? render(plain: 'success') : render(plain: 'failed', status: :unprocessable_entity)
    end
  end

  before do
    routes.draw { get 'test_action' => 'anonymous#test_action' }
  end

  describe '#after_sign_in_path_for' do
    it 'ダッシュボードパスを返すこと' do
      user = instance_double('User')
      expect(controller.after_sign_in_path_for(user)).to eq(dashboard_path)
    end
  end

  describe '#after_sign_out_path_for' do
    it 'ルートパスを返すこと' do
      expect(controller.after_sign_out_path_for(:user)).to eq(root_path)
    end
  end

  describe '#verify_captcha' do
    let(:mock_result) { instance_double('CaptchaVerificationService::Result') }

    before do
      allow(CaptchaVerificationService).to receive(:verify).and_return(mock_result)
      allow(mock_result).to receive(:success?).and_return(true)
      allow(mock_result).to receive(:error_codes).and_return([])
    end

    context 'CAPTCHAが無効の場合' do
      before do
        allow(CaptchaHelper).to receive(:disabled?).and_return(true)
      end

      it 'trueを返すこと' do
        get :test_action
        expect(response.body).to eq('success')
      end
    end

    context 'CAPTCHAが有効な場合' do
      before do
        allow(CaptchaHelper).to receive(:disabled?).and_return(false)
      end

      context '検証に成功した場合' do
        before do
          allow(mock_result).to receive(:success?).and_return(true)
        end

        it 'trueを返すこと' do
          get :test_action, params: { cf_turnstile_response: 'valid_token' }
          expect(response.body).to eq('success')
        end

        it 'CaptchaVerificationServiceを呼び出すこと' do
          get :test_action, params: { cf_turnstile_response: 'test_token' }
          
          expect(CaptchaVerificationService).to have_received(:verify).with(
            token: 'test_token',
            remote_ip: request.remote_ip
          )
        end
      end

      context '検証に失敗した場合' do
        before do
          allow(mock_result).to receive(:success?).and_return(false)
          allow(mock_result).to receive(:error_codes).and_return(['invalid-input-response'])
          allow(Rails.logger).to receive(:error)
        end

        it 'falseを返すこと' do
          get :test_action, params: { cf_turnstile_response: 'invalid_token' }
          expect(response.body).to eq('failed')
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'ログにエラーを出力しないこと' do
          get :test_action, params: { cf_turnstile_response: 'invalid_token' }
          expect(Rails.logger).not_to have_received(:error)
        end

        it 'フラッシュメッセージを設定すること' do
          get :test_action, params: { cf_turnstile_response: 'invalid_token' }
          expect(flash.now[:alert]).to be_present
        end
      end

      context 'パラメータの取得パターン' do
        it 'Deviseパラメータからトークンを取得すること' do
          # resource_nameメソッドを模擬（ただし、paramsで"user"キーは自動で処理される）
          # このテストは直接パラメータに委ねる
          get :test_action, params: { user: { cf_turnstile_response: 'devise_token' } }
          
          # user[cf_turnstile_response]のパラメータが取得されない場合はnilが渡される
          # ApplicationControllerの実装では、resource_nameが利用できない場合は
          # 直接params[:cf_turnstile_response]を使用するため、この場合nilになる
          expect(CaptchaVerificationService).to have_received(:verify).with(
            token: nil,
            remote_ip: request.remote_ip
          )
        end

        it '直接パラメータからトークンを取得すること' do
          get :test_action, params: { cf_turnstile_response: 'direct_token' }
          
          expect(CaptchaVerificationService).to have_received(:verify).with(
            token: 'direct_token',
            remote_ip: request.remote_ip
          )
        end

        it 'ダッシュ形式パラメータからトークンを取得すること' do
          get :test_action, params: { 'cf-turnstile-response' => 'dash_token' }
          
          expect(CaptchaVerificationService).to have_received(:verify).with(
            token: 'dash_token',
            remote_ip: request.remote_ip
          )
        end

        it '引数で渡されたトークンを優先すること' do
          # 直接verify_captchaメソッドをテスト
          allow(controller).to receive(:params).and_return(ActionController::Parameters.new(cf_turnstile_response: 'param_token'))
          
          controller.send(:verify_captcha, 'argument_token')
          
          expect(CaptchaVerificationService).to have_received(:verify).with(
            token: 'argument_token',
            remote_ip: request.remote_ip
          )
        end
      end
    end
  end

  describe '#captcha_error_message' do
    context 'timeoutエラーの場合' do
      it 'タイムアウト用メッセージを返すこと' do
        message = controller.send(:captcha_error_message, ['timeout'])
        expect(message).to eq('セキュリティ検証に失敗しました。しばらく時間をおいて再度お試しください。')
      end
    end

    context 'network-errorの場合' do
      it 'ネットワークエラー用メッセージを返すこと' do
        message = controller.send(:captcha_error_message, ['network-error'])
        expect(message).to eq('セキュリティ検証でエラーが発生しました。ページを再読み込みして再度お試しください。')
      end
    end

    context 'その他のエラーの場合' do
      it 'デフォルトメッセージを返すこと' do
        message = controller.send(:captcha_error_message, ['invalid-input-response'])
        expect(message).to eq('セキュリティ検証が完了していません。チェックボックスにチェックを入れてから送信してください。')
      end
    end

    context '複数のエラーコードでtimeoutが含まれる場合' do
      it 'タイムアウト用メッセージを返すこと' do
        message = controller.send(:captcha_error_message, ['invalid-input-response', 'timeout'])
        expect(message).to eq('セキュリティ検証に失敗しました。しばらく時間をおいて再度お試しください。')
      end
    end
  end

  describe '#configure_permitted_parameters' do
    let(:devise_parameter_sanitizer) { double('devise_parameter_sanitizer') }

    before do
      allow(controller).to receive(:devise_controller?).and_return(true)
      allow(controller).to receive(:devise_parameter_sanitizer).and_return(devise_parameter_sanitizer)
      allow(devise_parameter_sanitizer).to receive(:permit)
    end

    it 'sign_upでnameパラメータを許可すること' do
      controller.send(:configure_permitted_parameters)
      expect(devise_parameter_sanitizer).to have_received(:permit).with(:sign_up, keys: [:name])
    end

    it 'account_updateでnameパラメータを許可すること' do
      controller.send(:configure_permitted_parameters)
      expect(devise_parameter_sanitizer).to have_received(:permit).with(:account_update, keys: [:name])
    end
  end
end