# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Shlink::BaseService do
  let(:base_url) { 'https://example.com' }
  let(:api_key) { 'test-api-key' }
  let(:service) { described_class.new(base_url: base_url, api_key: api_key) }

  describe '#initialize' do
    it 'base_urlとapi_keyが設定されること' do
      expect(service.base_url).to eq(base_url)
      expect(service.api_key).to eq(api_key)
    end

    it 'Faraday接続が構築されること' do
      expect(service.conn).to be_a(Faraday::Connection)
    end
  end

  describe '#handle_response' do
    let(:response_double) { double('response') }

    context '成功レスポンスの場合' do
      before do
        allow(response_double).to receive(:status).and_return(200)
        allow(response_double).to receive(:body).and_return({ 'data' => 'test' })
      end

      it 'レスポンスボディを返すこと' do
        result = service.send(:handle_response, response_double)
        expect(result).to eq({ 'data' => 'test' })
      end
    end

    context 'エラーレスポンスの場合' do
      before do
        allow(response_double).to receive(:status).and_return(404)
        allow(response_double).to receive(:body).and_return({ 'detail' => 'Not found' })
      end

      it 'Shlink::Errorを発生させること' do
        expect {
          service.send(:handle_response, response_double)
        }.to raise_error(Shlink::Error, 'Shlink API error (404): Not found')
      end
    end
  end

  describe '#extract_error_message' do
    it 'detail属性を抽出すること' do
      body = { 'detail' => 'Detailed error message' }
      result = service.send(:extract_error_message, body)
      expect(result).to eq('Detailed error message')
    end

    it 'title属性を抽出すること' do
      body = { 'title' => 'Title error message' }
      result = service.send(:extract_error_message, body)
      expect(result).to eq('Title error message')
    end

    it '文字列の場合はそのまま返すこと' do
      body = 'Plain error message'
      result = service.send(:extract_error_message, body)
      expect(result).to eq('Plain error message')
    end
  end

  describe '#api_headers' do
    it 'API Key headerを返すこと' do
      headers = service.send(:api_headers)
      expect(headers).to eq({ 'X-Api-Key' => api_key })
    end
  end
end
