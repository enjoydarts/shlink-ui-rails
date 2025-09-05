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
          .with(body: { longUrl: long_url }.to_json)
      end
    end

    context "有効期限を指定した場合（JST対応）" do
      around do |example|
        Time.use_zone('Asia/Tokyo') do
          example.run
        end
      end

      let(:valid_until) { 1.day.from_now }

      before do
        stub_request(:post, "https://test.example.com/rest/v3/short-urls")
          .with(
            headers: { "X-Api-Key" => "test-key" },
            body: { longUrl: long_url, validUntil: valid_until.iso8601 }
          )
          .to_return(
            status: 201,
            body: {
              shortUrl: "https://test.example.com/abc123",
              shortCode: "abc123",
              longUrl: long_url,
              validUntil: valid_until.iso8601
            }.to_json,
            headers: { "content-type" => "application/json" }
          )
      end

      it "有効期限付きで短縮URLを作成すること" do
        result = service.call(long_url: long_url, valid_until: valid_until)

        expect(result).to include(
          "shortUrl" => "https://test.example.com/abc123",
          "shortCode" => "abc123",
          "longUrl" => long_url,
          "validUntil" => valid_until.iso8601
        )
      end
    end

    context "有効期限とカスタムスラッグの両方を指定した場合（JST対応）" do
      around do |example|
        Time.use_zone('Asia/Tokyo') do
          example.run
        end
      end

      let(:custom_slug) { "custom-slug" }
      let(:valid_until) { 1.week.from_now }

      before do
        stub_request(:post, "https://test.example.com/rest/v3/short-urls")
          .with(
            headers: { "X-Api-Key" => "test-key" },
            body: { longUrl: long_url, customSlug: custom_slug, validUntil: valid_until.iso8601 }
          )
          .to_return(
            status: 201,
            body: {
              shortUrl: "https://test.example.com/#{custom_slug}",
              shortCode: custom_slug,
              longUrl: long_url,
              validUntil: valid_until.iso8601
            }.to_json,
            headers: { "content-type" => "application/json" }
          )
      end

      it "カスタムスラッグと有効期限の両方で短縮URLを作成すること" do
        result = service.call(long_url: long_url, slug: custom_slug, valid_until: valid_until)

        expect(result).to include(
          "shortCode" => custom_slug,
          "shortUrl" => "https://test.example.com/#{custom_slug}",
          "validUntil" => valid_until.iso8601
        )
      end
    end

    context "最大訪問回数を指定した場合" do
      let(:max_visits) { 50 }

      before do
        stub_request(:post, "https://test.example.com/rest/v3/short-urls")
          .with(
            headers: { "X-Api-Key" => "test-key" },
            body: { longUrl: long_url, maxVisits: max_visits }
          )
          .to_return(
            status: 201,
            body: {
              shortUrl: "https://test.example.com/abc123",
              shortCode: "abc123",
              longUrl: long_url,
              maxVisits: max_visits
            }.to_json,
            headers: { "content-type" => "application/json" }
          )
      end

      it "最大訪問回数付きで短縮URLを作成すること" do
        result = service.call(long_url: long_url, max_visits: max_visits)

        expect(result).to include(
          "shortUrl" => "https://test.example.com/abc123",
          "shortCode" => "abc123",
          "longUrl" => long_url,
          "maxVisits" => max_visits
        )
      end
    end

    context "有効期限、カスタムスラッグ、最大訪問回数をすべて指定した場合（JST対応）" do
      around do |example|
        Time.use_zone('Asia/Tokyo') do
          example.run
        end
      end

      let(:custom_slug) { "custom-slug" }
      let(:valid_until) { 1.week.from_now }
      let(:max_visits) { 25 }

      before do
        stub_request(:post, "https://test.example.com/rest/v3/short-urls")
          .with(
            headers: { "X-Api-Key" => "test-key" },
            body: { longUrl: long_url, customSlug: custom_slug, validUntil: valid_until.iso8601, maxVisits: max_visits }
          )
          .to_return(
            status: 201,
            body: {
              shortUrl: "https://test.example.com/#{custom_slug}",
              shortCode: custom_slug,
              longUrl: long_url,
              validUntil: valid_until.iso8601,
              maxVisits: max_visits
            }.to_json,
            headers: { "content-type" => "application/json" }
          )
      end

      it "すべてのオプションで短縮URLを作成すること" do
        result = service.call(long_url: long_url, slug: custom_slug, valid_until: valid_until, max_visits: max_visits)

        expect(result).to include(
          "shortCode" => custom_slug,
          "shortUrl" => "https://test.example.com/#{custom_slug}",
          "validUntil" => valid_until.iso8601,
          "maxVisits" => max_visits
        )
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

    it "有効期限付きでも同じ動作をすること（JST対応）" do
      Time.use_zone('Asia/Tokyo') do
        valid_until = 1.day.from_now
        stub_request(:post, "https://test.example.com/rest/v3/short-urls")
          .with(body: { longUrl: long_url, validUntil: valid_until.iso8601 })
          .to_return(
            status: 201,
            body: { shortUrl: "https://test.example.com/test" }.to_json,
            headers: { "content-type" => "application/json" }
          )

        result = service.call!(long_url: long_url, valid_until: valid_until)
        expect(result["shortUrl"]).to eq("https://test.example.com/test")
      end
    end

    it "最大訪問回数付きでも同じ動作をすること" do
      max_visits = 30
      stub_request(:post, "https://test.example.com/rest/v3/short-urls")
        .with(body: { longUrl: long_url, maxVisits: max_visits })
        .to_return(
          status: 201,
          body: { shortUrl: "https://test.example.com/test" }.to_json,
          headers: { "content-type" => "application/json" }
        )

      result = service.call!(long_url: long_url, max_visits: max_visits)
      expect(result["shortUrl"]).to eq("https://test.example.com/test")
    end
  end

  describe "プライベートメソッド" do
    describe "#build_payload" do
      it "スラッグなしの場合はlongUrlのみを含むこと" do
        payload = service.send(:build_payload, long_url, nil, nil, nil)
        expect(payload).to eq({ longUrl: long_url })
      end

      it "スラッグありの場合はcustomSlugも含むこと" do
        payload = service.send(:build_payload, long_url, "test-slug", nil, nil)
        expect(payload).to eq({ longUrl: long_url, customSlug: "test-slug" })
      end

      it "空文字のスラッグは無視されること" do
        payload = service.send(:build_payload, long_url, "", nil, nil)
        expect(payload).to eq({ longUrl: long_url })
      end

      it "有効期限ありの場合はvalidUntilも含むこと（JST対応）" do
        Time.use_zone('Asia/Tokyo') do
          valid_until = 1.day.from_now
          payload = service.send(:build_payload, long_url, nil, valid_until, nil)
          expect(payload).to eq({ longUrl: long_url, validUntil: valid_until.iso8601 })
        end
      end

      it "最大訪問回数ありの場合はmaxVisitsも含むこと" do
        max_visits = 20
        payload = service.send(:build_payload, long_url, nil, nil, max_visits)
        expect(payload).to eq({ longUrl: long_url, maxVisits: max_visits })
      end

      it "すべてのオプションがある場合はすべて含むこと（JST対応）" do
        Time.use_zone('Asia/Tokyo') do
          valid_until = 1.day.from_now
          max_visits = 15
          payload = service.send(:build_payload, long_url, "test-slug", valid_until, max_visits)
          expect(payload).to eq({
            longUrl: long_url,
            customSlug: "test-slug",
            validUntil: valid_until.iso8601,
            maxVisits: max_visits
          })
        end
      end

      it "有効期限がnilの場合はvalidUntilを含まないこと" do
        payload = service.send(:build_payload, long_url, "test-slug", nil, 10)
        expect(payload).to eq({ longUrl: long_url, customSlug: "test-slug", maxVisits: 10 })
      end

      it "最大訪問回数がnilの場合はmaxVisitsを含まないこと" do
        Time.use_zone('Asia/Tokyo') do
          valid_until = 1.day.from_now
          payload = service.send(:build_payload, long_url, "test-slug", valid_until, nil)
          expect(payload).to eq({ longUrl: long_url, customSlug: "test-slug", validUntil: valid_until.iso8601 })
        end
      end
    end
  end
end
