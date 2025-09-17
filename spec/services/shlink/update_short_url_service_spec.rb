require 'rails_helper'

RSpec.describe Shlink::UpdateShortUrlService, type: :service do
  let(:short_code) { 'test123' }
  let(:base_url) { 'https://example.com' }
  let(:api_key) { 'test-api-key' }
  let(:service) { described_class.new(base_url: base_url, api_key: api_key) }

  describe '#call' do
    let(:response_body) do
      {
        "shortCode" => short_code,
        "shortUrl" => "#{base_url}/#{short_code}",
        "longUrl" => "https://google.com",
        "title" => "Updated Title",
        "tags" => [ "tag1", "tag2" ],
        "meta" => {},
        "validSince" => "2024-01-01T00:00:00Z",
        "validUntil" => "2024-12-31T23:59:59Z",
        "maxVisits" => 100,
        "crawlable" => true,
        "forwardQuery" => true
      }
    end

    context '正常な更新の場合' do
      before do
        stub_request(:patch, "#{base_url}/rest/v3/short-urls/#{short_code}")
          .with(
            headers: {
              'Content-Type' => 'application/json',
              'X-Api-Key' => api_key
            }
          )
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'タイトルを更新できる' do
        result = service.call(
          short_code: short_code,
          title: "Updated Title"
        )

        expect(result["title"]).to eq("Updated Title")
      end

      it '元のURLを更新できる' do
        result = service.call(
          short_code: short_code,
          long_url: "https://google.com"
        )

        expect(result["longUrl"]).to eq("https://google.com")
      end

      it 'タグを更新できる' do
        result = service.call(
          short_code: short_code,
          tags: [ "tag1", "tag2" ]
        )

        expect(result["tags"]).to eq([ "tag1", "tag2" ])
      end

      it '有効期限を更新できる' do
        valid_until = DateTime.new(2024, 12, 31, 23, 59, 59)
        result = service.call(
          short_code: short_code,
          valid_until: valid_until
        )

        expect(result["validUntil"]).to eq("2024-12-31T23:59:59Z")
      end

      it '訪問制限を更新できる' do
        result = service.call(
          short_code: short_code,
          max_visits: 100
        )

        expect(result["maxVisits"]).to eq(100)
      end

      it 'カスタムスラッグを更新できる' do
        service.call(
          short_code: short_code,
          custom_slug: "new-slug"
        )

        expect(WebMock).to have_requested(:patch, "#{base_url}/rest/v3/short-urls/#{short_code}")
          .with(body: hash_including("customSlug" => "new-slug"))
      end

      it '複数のパラメータを同時に更新できる' do
        valid_until = DateTime.new(2024, 12, 31, 23, 59, 59)

        service.call(
          short_code: short_code,
          title: "Updated Title",
          long_url: "https://google.com",
          tags: [ "tag1", "tag2" ],
          valid_until: valid_until,
          max_visits: 100
        )

        expect(WebMock).to have_requested(:patch, "#{base_url}/rest/v3/short-urls/#{short_code}")
          .with(body: hash_including(
            "title" => "Updated Title",
            "longUrl" => "https://google.com",
            "tags" => [ "tag1", "tag2" ],
            "validUntil" => "2024-12-31T23:59:59+00:00",
            "maxVisits" => 100
          ))
      end
    end

    context '有効期限・訪問制限をクリアする場合' do
      before do
        stub_request(:patch, "#{base_url}/rest/v3/short-urls/#{short_code}")
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it '有効期限をクリアできる' do
        service.call(
          short_code: short_code,
          valid_until: ""
        )

        expect(WebMock).to have_requested(:patch, "#{base_url}/rest/v3/short-urls/#{short_code}")
          .with(body: hash_including("validUntil" => nil))
      end

      it '訪問制限をクリアできる' do
        service.call(
          short_code: short_code,
          max_visits: ""
        )

        expect(WebMock).to have_requested(:patch, "#{base_url}/rest/v3/short-urls/#{short_code}")
          .with(body: hash_including("maxVisits" => nil))
      end
    end

    context 'エラーレスポンスの場合' do
      before do
        stub_request(:patch, "#{base_url}/rest/v3/short-urls/#{short_code}")
          .to_return(
            status: 404,
            body: { "detail" => "Short URL not found" }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'Shlink::Errorを発生させる' do
        expect {
          service.call(short_code: short_code, title: "Updated Title")
        }.to raise_error(Shlink::Error, /Short URL not found/)
      end
    end

    context 'ネットワークエラーの場合' do
      before do
        stub_request(:patch, "#{base_url}/rest/v3/short-urls/#{short_code}")
          .to_raise(Faraday::ConnectionFailed.new("Connection failed"))
      end

      it 'Shlink::Errorを発生させる' do
        expect {
          service.call(short_code: short_code, title: "Updated Title")
        }.to raise_error(Shlink::Error, /HTTP error: Connection failed/)
      end
    end

    context '空のパラメータの場合' do
      it '空のペイロードを送信しない' do
        result = service.call(
          short_code: short_code,
          title: nil,
          long_url: "",
          tags: [],
          valid_until: nil,
          max_visits: nil
        )

        expect(result).to eq({})
        expect(WebMock).not_to have_requested(:patch, "#{base_url}/rest/v3/short-urls/#{short_code}")
      end
    end
  end
end
