require 'rails_helper'

RSpec.describe Shlink::DeleteShortUrlService, type: :service do
  let(:short_code) { 'abc123' }
  let(:service) { described_class.new(short_code) }
  let(:base_url) { 'https://test-shlink.example.com' }
  let(:api_key) { 'test_api_key' }

  before do
    ENV['SHLINK_BASE_URL'] = base_url
    ENV['SHLINK_API_KEY'] = api_key
  end

  describe '#call' do
    context '削除が成功した場合' do
      before do
        stub_request(:delete, "#{base_url}/rest/v3/short-urls/#{short_code}")
          .with(headers: { 'X-Api-Key' => api_key })
          .to_return(status: 204)
      end

      it 'trueを返すこと' do
        expect(service.call).to be true
      end

      it 'ログを出力すること' do
        expect(Rails.logger).to receive(:info).with("Successfully deleted short URL: #{short_code}")
        service.call
      end
    end

    context '短縮URLが見つからない場合' do
      before do
        stub_request(:delete, "#{base_url}/rest/v3/short-urls/#{short_code}")
          .with(headers: { 'X-Api-Key' => api_key })
          .to_return(
            status: 404,
            body: { "detail" => "No short URL found with provided identifier" }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'Shlink::Errorを発生させること' do
        expect { service.call }.to raise_error(Shlink::Error, "短縮URLが見つかりません")
      end
    end

    context '削除できない場合' do
      before do
        stub_request(:delete, "#{base_url}/rest/v3/short-urls/#{short_code}")
          .with(headers: { 'X-Api-Key' => api_key })
          .to_return(
            status: 422,
            body: { "detail" => "Cannot delete this short URL" }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'Shlink::Errorを発生させること' do
        expect { service.call }.to raise_error(Shlink::Error, "この短縮URLは削除できません")
      end
    end

    context 'ネットワークエラーが発生した場合' do
      before do
        stub_request(:delete, "#{base_url}/rest/v3/short-urls/#{short_code}")
          .to_raise(Faraday::ConnectionFailed.new("Connection failed"))
      end

      it 'Shlink::Errorを発生させること' do
        expect { service.call }.to raise_error(Shlink::Error, /ネットワークエラーが発生しました/)
      end
    end
  end

  describe '#call!' do
    context '削除が成功した場合' do
      before do
        stub_request(:delete, "#{base_url}/rest/v3/short-urls/#{short_code}")
          .with(headers: { 'X-Api-Key' => api_key })
          .to_return(status: 204)
      end

      it 'trueを返すこと' do
        expect(service.call!).to be true
      end
    end

    context 'エラーが発生した場合' do
      before do
        stub_request(:delete, "#{base_url}/rest/v3/short-urls/#{short_code}")
          .to_return(status: 404)
      end

      it 'Shlink::Errorを発生させること' do
        expect { service.call! }.to raise_error(Shlink::Error)
      end
    end
  end
end
