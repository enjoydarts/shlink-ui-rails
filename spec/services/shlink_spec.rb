require 'rails_helper'

RSpec.describe Shlink, type: :service do
  describe Shlink::Client do
    let(:base_url) { 'https://shlink.example.com' }
    let(:api_key) { 'test-api-key' }
    let(:client) { described_class.new(base_url: base_url, api_key: api_key) }

    describe '初期化' do
      context 'カスタムパラメータの場合' do
        it 'ベースURLとAPIキーを設定する' do
          expect(client.instance_variable_get(:@api_key)).to eq(api_key)
          # Faraday connection URLは直接アクセスできないため、動作確認はHTTPリクエストで行う
        end
      end

      context '環境変数の場合' do
        before do
          allow(ENV).to receive(:[]).and_call_original
          allow(ENV).to receive(:[]).with('SHLINK_BASE_URL').and_return('https://env.example.com')
          allow(ENV).to receive(:[]).with('SHLINK_API_KEY').and_return('env-api-key')
        end

        let(:env_client) { described_class.new }

        it '環境変数を使用する' do
          expect(env_client.instance_variable_get(:@api_key)).to eq('env-api-key')
        end
      end
    end

    describe '短縮URL作成' do
      let(:long_url) { 'https://example.com/very/long/url' }
      let(:slug) { 'custom-slug' }

      context 'APIリクエストが成功した場合' do
        let(:api_response) do
          {
            'shortUrl' => 'https://shlink.example.com/abc123',
            'shortCode' => 'abc123',
            'longUrl' => long_url,
            'dateCreated' => '2025-01-01T00:00:00+00:00',
            'tags' => [],
            'meta' => {
              'validSince' => nil,
              'validUntil' => nil,
              'maxVisits' => nil
            },
            'domain' => nil,
            'title' => 'Example Page Title',
            'crawlable' => false,
            'forwardQuery' => true
          }
        end

        before do
          stub_request(:post, "#{base_url}/rest/v3/short-urls")
            .with(
              headers: {
                'X-Api-Key' => api_key,
                'Content-Type' => 'application/json'
              },
              body: {
                longUrl: long_url,
                customSlug: slug
              }.to_json
            )
            .to_return(
              status: 201,
              body: api_response.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'APIレスポンスを返す' do
          result = client.create_short_url(long_url, slug)
          expect(result).to eq(api_response)
        end

        it 'レスポンスに短縮URLを含む' do
          result = client.create_short_url(long_url, slug)
          expect(result['shortUrl']).to eq('https://shlink.example.com/abc123')
        end
      end

      context 'slugが空文字の場合' do
        let(:slug) { '' }

        before do
          stub_request(:post, "#{base_url}/rest/v3/short-urls")
            .with(
              headers: {
                'X-Api-Key' => api_key,
                'Content-Type' => 'application/json'
              },
              body: {
                longUrl: long_url
              }.to_json
            )
            .to_return(
              status: 201,
              body: {
                'shortUrl' => 'https://shlink.example.com/xyz789',
                'shortCode' => 'xyz789',
                'longUrl' => long_url
              }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'リクエストにcustomSlugを含まない' do
          client.create_short_url(long_url, slug)
          # WebMock will verify the request body automatically
        end
      end

      context 'slugがnilの場合' do
        let(:slug) { nil }

        before do
          stub_request(:post, "#{base_url}/rest/v3/short-urls")
            .with(
              headers: {
                'X-Api-Key' => api_key,
                'Content-Type' => 'application/json'
              },
              body: {
                longUrl: long_url
              }.to_json
            )
            .to_return(
              status: 201,
              body: {
                'shortUrl' => 'https://shlink.example.com/xyz789',
                'shortCode' => 'xyz789',
                'longUrl' => long_url
              }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'リクエストにcustomSlugを含まない' do
          client.create_short_url(long_url, slug)
          # WebMock will verify the request body automatically
        end
      end

      context 'APIがエラーステータスを返す場合' do
        before do
          stub_request(:post, "#{base_url}/rest/v3/short-urls")
            .with(
              headers: {
                'X-Api-Key' => api_key,
                'Content-Type' => 'application/json'
              }
            )
            .to_return(
              status: 400,
              body: {
                'title' => 'Invalid URL',
                'detail' => 'The provided URL is not valid'
              }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'Shlink::Errorをエラーメッセージとともに発生させる' do
          expect {
            client.create_short_url(long_url, slug)
          }.to raise_error(Shlink::Error, 'Shlink API error (400): The provided URL is not valid')
        end
      end

      context 'APIが詳細メッセージ付きエラーを返す場合' do
        before do
          stub_request(:post, "#{base_url}/rest/v3/short-urls")
            .to_return(
              status: 422,
              body: {
                'detail' => 'Custom slug already exists'
              }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it 'Shlink::Errorを詳細メッセージとともに発生させる' do
          expect {
            client.create_short_url(long_url, slug)
          }.to raise_error(Shlink::Error, 'Shlink API error (422): Custom slug already exists')
        end
      end

      context 'APIがJSON以外のレスポンスを返す場合' do
        before do
          stub_request(:post, "#{base_url}/rest/v3/short-urls")
            .to_return(
              status: 500,
              body: 'Internal Server Error',
              headers: { 'Content-Type' => 'text/plain' }
            )
        end

        it 'Shlink::Errorをレスポンスボディとともに発生させる' do
          expect {
            client.create_short_url(long_url, slug)
          }.to raise_error(Shlink::Error, 'Shlink API error (500): Internal Server Error')
        end
      end

      context 'ネットワークエラーが発生した場合' do
        before do
          stub_request(:post, "#{base_url}/rest/v3/short-urls")
            .to_raise(Faraday::ConnectionFailed.new('Connection failed'))
        end

        it 'Shlink::Errorをネットワークエラーメッセージとともに発生させる' do
          expect {
            client.create_short_url(long_url, slug)
          }.to raise_error(Shlink::Error, 'HTTP error: Connection failed')
        end
      end

      context 'タイムアウトが発生した場合' do
        before do
          stub_request(:post, "#{base_url}/rest/v3/short-urls")
            .to_raise(Faraday::TimeoutError.new('Request timeout'))
        end

        it 'Shlink::Errorをタイムアウトエラーメッセージとともに発生させる' do
          expect {
            client.create_short_url(long_url, slug)
          }.to raise_error(Shlink::Error, 'HTTP error: Request timeout')
        end
      end
    end
  end

  describe Shlink::Error do
    it 'StandardErrorである' do
      expect(Shlink::Error.new).to be_a(StandardError)
    end

    it 'メッセージで初期化できる' do
      error = Shlink::Error.new('Test error message')
      expect(error.message).to eq('Test error message')
    end
  end
end