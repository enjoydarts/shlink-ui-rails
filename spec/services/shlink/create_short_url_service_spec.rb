require 'rails_helper'

RSpec.describe Shlink::CreateShortUrlService, "短縮URL作成サービス" do
  let(:service) { Shlink::CreateShortUrlService.new(base_url: "https://test.example.com", api_key: "test-key") }
  let(:long_url) { "https://example.com/very/long/url" }

  before do
    stub_request(:any, /test\.example\.com/).to_return(status: 404)
  end

  describe "#call" do
    context "有効なURLを指定した場合" do
      before do
        stub_request(:post, "https://test.example.com/rest/v3/short-urls")
          .with(
            headers: { "X-Api-Key" => "test-key" },
            body: { longUrl: long_url }
          )
          .to_return(
            status: 201,
            body: {
              shortUrl: "https://test.example.com/abc123",
              shortCode: "abc123",
              longUrl: long_url
            }.to_json,
            headers: { "content-type" => "application/json" }
          )
      end

      it "短縮URLデータを返すこと" do
        result = service.call(long_url: long_url)

        expect(result).to include(
          "shortUrl" => "https://test.example.com/abc123",
          "shortCode" => "abc123",
          "longUrl" => long_url
        )
      end
    end

    context "カスタムスラッグを指定した場合" do
      let(:custom_slug) { "custom-slug" }

      before do
        stub_request(:post, "https://test.example.com/rest/v3/short-urls")
          .with(
            headers: { "X-Api-Key" => "test-key" },
            body: { longUrl: long_url, customSlug: custom_slug }
          )
          .to_return(
            status: 201,
            body: {
              shortUrl: "https://test.example.com/#{custom_slug}",
              shortCode: custom_slug,
              longUrl: long_url
            }.to_json,
            headers: { "content-type" => "application/json" }
          )
      end

      it "カスタムスラッグで短縮URLを作成すること" do
        result = service.call(long_url: long_url, slug: custom_slug)

        expect(result).to include(
          "shortCode" => custom_slug,
          "shortUrl" => "https://test.example.com/#{custom_slug}"
        )
      end
    end

    context "空のスラッグを指定した場合" do
      before do
        stub_request(:post, "https://test.example.com/rest/v3/short-urls")
          .with(
            headers: { "X-Api-Key" => "test-key" },
            body: { longUrl: long_url }
          )
          .to_return(
            status: 201,
            body: {
              shortUrl: "https://test.example.com/auto123",
              shortCode: "auto123",
              longUrl: long_url
            }.to_json,
            headers: { "content-type" => "application/json" }
          )
      end

      it "customSlugパラメータを送信しないこと" do
        service.call(long_url: long_url, slug: "")

        expect(WebMock).to have_requested(:post, "https://test.example.com/rest/v3/short-urls")
          .with(body: hash_not_including(:customSlug))
      end
    end

    context "API エラーが発生した場合" do
      before do
        stub_request(:post, "https://test.example.com/rest/v3/short-urls")
          .to_return(
            status: 400,
            body: { detail: "Invalid URL provided" }.to_json,
            headers: { "content-type" => "application/json" }
          )
      end

      it "Shlink::Errorを発生させること" do
        expect {
          service.call(long_url: "invalid-url")
        }.to raise_error(Shlink::Error, /Shlink API error.*Invalid URL provided/)
      end
    end

    context "ネットワークエラーが発生した場合" do
      before do
        stub_request(:post, "https://test.example.com/rest/v3/short-urls")
          .to_raise(Faraday::ConnectionFailed.new("接続失敗"))
      end

      it "Shlink::Errorを発生させること" do
        expect {
          service.call(long_url: long_url)
        }.to raise_error(Shlink::Error, /HTTP error/)
      end
    end
  end

  describe "#call!" do
    it "callメソッドと同じ動作をすること" do
      stub_request(:post, "https://test.example.com/rest/v3/short-urls")
        .to_return(
          status: 201,
          body: { shortUrl: "https://test.example.com/test" }.to_json,
          headers: { "content-type" => "application/json" }
        )

      result = service.call!(long_url: long_url)
      expect(result["shortUrl"]).to eq("https://test.example.com/test")
    end
  end

  describe "プライベートメソッド" do
    describe "#build_payload" do
      it "スラッグなしの場合はlongUrlのみを含むこと" do
        payload = service.send(:build_payload, long_url, nil)
        expect(payload).to eq({ longUrl: long_url })
      end

      it "スラッグありの場合はcustomSlugも含むこと" do
        payload = service.send(:build_payload, long_url, "test-slug")
        expect(payload).to eq({ longUrl: long_url, customSlug: "test-slug" })
      end

      it "空文字のスラッグは無視されること" do
        payload = service.send(:build_payload, long_url, "")
        expect(payload).to eq({ longUrl: long_url })
      end
    end
  end
end
