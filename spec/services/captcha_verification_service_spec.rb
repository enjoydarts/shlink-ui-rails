# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CaptchaVerificationService, type: :service do
  let(:service) { described_class.new(token: 'test_token', remote_ip: '127.0.0.1') }
  let(:successful_response) do
    {
      'success' => true,
      'challenge_ts' => '2023-01-01T00:00:00.000Z',
      'hostname' => 'localhost'
    }
  end
  let(:failed_response) do
    {
      'success' => false,
      'error-codes' => [ 'invalid-input-response' ]
    }
  end

  before do
    # Settingsのモック化（DB接続を避けるため）
    settings_mock = double('settings')
    turnstile_mock = double('turnstile_settings',
      secret_key: 'test_secret_key',
      verify_url: 'https://challenges.cloudflare.com/turnstile/v0/siteverify',
      timeout: 30
    )
    allow(Settings).to receive(:captcha).and_return(double('captcha', turnstile: turnstile_mock))
  end

  describe '#initialize' do
    it '適切にパラメータを設定すること' do
      expect(service.token).to eq('test_token')
      expect(service.remote_ip).to eq('127.0.0.1')
    end

    context 'remote_ipが省略された場合' do
      let(:service_without_ip) { described_class.new(token: 'test_token', remote_ip: nil) }

      it 'remote_ipがnilであること' do
        expect(service_without_ip.remote_ip).to be_nil
      end
    end
  end

  describe '#verify' do
    let(:mock_response) { double('response', success?: true, body: response_body.to_json) }
    let(:response_body) do
      {
        'success' => true,
        'challenge_ts' => '2023-01-01T00:00:00.000Z',
        'hostname' => 'localhost'
      }
    end

    context 'CAPTCHAが無効化されている場合' do
      before do
        allow(CaptchaHelper).to receive(:disabled?).and_return(true)
      end

      it '成功結果を返すこと' do
        result = service.verify
        expect(result.success?).to be true
      end
    end

    context 'CAPTCHAが有効な場合' do
      before do
        allow(CaptchaHelper).to receive(:disabled?).and_return(false)
      end

      context '検証に成功した場合' do
        before do
          stub_request(:post, 'https://challenges.cloudflare.com/turnstile/v0/siteverify')
            .with(
              body: {
                'secret' => 'test_secret_key',
                'response' => 'test_token',
                'remoteip' => '127.0.0.1'
              }
            )
            .to_return(
              status: 200,
              body: successful_response.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'trueを返すこと' do
          result = service.verify
          expect(result.success?).to be true
        end
      end

      context '検証に失敗した場合' do
        before do
          stub_request(:post, 'https://challenges.cloudflare.com/turnstile/v0/siteverify')
            .with(
              body: {
                'secret' => 'test_secret_key',
                'response' => 'test_token',
                'remoteip' => '127.0.0.1'
              }
            )
            .to_return(
              status: 200,
              body: failed_response.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'falseを返すこと' do
          result = service.verify
          expect(result.success?).to be false
        end

        it 'エラーログを出力しないこと' do
          allow(Rails.logger).to receive(:error)
          service.verify
          expect(Rails.logger).not_to have_received(:error)
        end
      end

      context 'ネットワークエラーが発生した場合' do
        before do
          stub_request(:post, 'https://challenges.cloudflare.com/turnstile/v0/siteverify')
            .to_raise(Faraday::Error)
        end

        it 'falseを返すこと' do
          result = service.verify
          expect(result.success?).to be false
        end

        it 'エラーログを出力すること' do
          allow(Rails.logger).to receive(:error)
          service.verify
          expect(Rails.logger).to have_received(:error)
        end
      end

      context 'タイムアウトエラーが発生した場合' do
        before do
          stub_request(:post, 'https://challenges.cloudflare.com/turnstile/v0/siteverify')
            .to_raise(Faraday::TimeoutError)
        end

        it 'falseを返すこと' do
          result = service.verify
          expect(result.success?).to be false
        end

        it 'エラーログを出力しないこと' do
          allow(Rails.logger).to receive(:error)
          service.verify
          expect(Rails.logger).not_to have_received(:error)
        end
      end

      context 'HTTPエラーが発生した場合' do
        before do
          stub_request(:post, 'https://challenges.cloudflare.com/turnstile/v0/siteverify')
            .to_return(status: 500, body: 'Internal Server Error')
        end

        it 'falseを返すこと' do
          result = service.verify
          expect(result.success?).to be false
        end

        it 'エラーログを出力しないこと' do
          allow(Rails.logger).to receive(:error)
          service.verify
          expect(Rails.logger).not_to have_received(:error)
        end
      end

      context 'JSONパースエラーが発生した場合' do
        before do
          stub_request(:post, 'https://challenges.cloudflare.com/turnstile/v0/siteverify')
            .to_return(status: 200, body: 'invalid json')
        end

        it 'falseを返すこと' do
          result = service.verify
          expect(result.success?).to be false
        end

        it 'エラーログを出力しないこと' do
          allow(Rails.logger).to receive(:error)
          service.verify
          expect(Rails.logger).not_to have_received(:error)
        end
      end

      context 'remote_ipがnilの場合' do
        let(:service_without_ip) { described_class.new(token: 'test_token', remote_ip: nil) }

        before do
          allow(CaptchaHelper).to receive(:disabled?).and_return(false)
          stub_request(:post, 'https://challenges.cloudflare.com/turnstile/v0/siteverify')
            .with(
              body: {
                'secret' => 'test_secret_key',
                'response' => 'test_token'
              }
            )
            .to_return(
              status: 200,
              body: successful_response.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'remote_ipなしでリクエストを送信すること' do
          result = service_without_ip.verify
          expect(result.success?).to be true
        end
      end
    end

    context 'tokenが空の場合' do
      let(:empty_service) { described_class.new(token: '', remote_ip: '127.0.0.1') }

      before do
        allow(CaptchaHelper).to receive(:disabled?).and_return(false)
      end

      it 'falseを返すこと' do
        result = empty_service.verify
        expect(result.success?).to be false
      end
    end

    context 'tokenがnilの場合' do
      let(:nil_service) { described_class.new(token: nil, remote_ip: '127.0.0.1') }

      before do
        allow(CaptchaHelper).to receive(:disabled?).and_return(false)
      end

      it 'falseを返すこと' do
        result = nil_service.verify
        expect(result.success?).to be false
      end
    end
  end

  describe '.verify' do
    it 'インスタンスメソッドverifyを呼び出すこと' do
      mock_result = double('result', success?: true)
      allow_any_instance_of(described_class).to receive(:verify).and_return(mock_result)

      result = described_class.verify(token: 'test_token', remote_ip: '127.0.0.1')

      expect(result.success?).to be true
    end

    context 'remote_ipが省略された場合' do
      it 'インスタンスメソッドverifyを呼び出すこと' do
        mock_result = double('result', success?: false)
        allow_any_instance_of(described_class).to receive(:verify).and_return(mock_result)

        result = described_class.verify(token: 'test_token')

        expect(result.success?).to be false
      end
    end
  end

  describe 'プライベートメソッド' do
    describe 'verification_params' do
      it '正しいパラメータを構築すること' do
        params = service.send(:verification_params)

        expect(params).to eq({
          secret: 'test_secret_key',
          response: 'test_token',
          remoteip: '127.0.0.1'
        })
      end

      context 'remote_ipがnilの場合' do
        let(:service_without_ip) { described_class.new(token: 'test_token', remote_ip: nil) }

        it 'remoteipを含まないパラメータを構築すること' do
          params = service_without_ip.send(:verification_params)

          expect(params).to eq({
            secret: 'test_secret_key',
            response: 'test_token'
          })
        end
      end
    end
  end
end
