require 'rails_helper'

RSpec.describe Shlink::GetQrCodeService, "QRコード取得サービス" do
  let(:service) { Shlink::GetQrCodeService.new(base_url: "https://test.example.com", api_key: "test-key") }
  let(:short_code) { "abc123" }

  before do
    stub_request(:any, /test\.example\.com/).to_return(status: 404)
  end

  describe "#call" do
    context "正常なレスポンスを受信した場合" do
      before do
        stub_request(:get, "https://test.example.com/#{short_code}/qr-code")
          .with(
            query: { size: "300", format: "png" },
            headers: { "X-Api-Key" => "test-key" }
          )
          .to_return(
            status: 200,
            body: "fake-qr-image-data",
            headers: { "content-type" => "image/png" }
          )
      end

      it "QRコード画像データを返すこと" do
        result = service.call(short_code: short_code)

        expect(result).to include(
          content_type: "image/png",
          data: "fake-qr-image-data",
          format: "png"
        )
      end
    end

    context "カスタムオプションを指定した場合" do
      before do
        stub_request(:get, "https://test.example.com/#{short_code}/qr-code")
          .with(
            query: { size: "400", format: "svg", margin: "10" },
            headers: { "X-Api-Key" => "test-key" }
          )
          .to_return(
            status: 200,
            body: "<svg>fake-svg-data</svg>",
            headers: { "content-type" => "image/svg+xml" }
          )
      end

      it "指定されたオプションでQRコードを取得すること" do
        result = service.call(short_code: short_code, size: 400, format: "svg", margin: 10)

        expect(result).to include(
          content_type: "image/svg+xml",
          data: "<svg>fake-svg-data</svg>",
          format: "svg"
        )
      end
    end

    context "最初のエンドポイントが失敗し、代替エンドポイントが成功する場合" do
      before do
        stub_request(:get, "https://test.example.com/#{short_code}/qr-code")
          .with(headers: { "X-Api-Key" => "test-key" })
          .to_return(status: 404)

        stub_request(:get, "https://test.example.com/rest/v3/short-urls/#{short_code}/qr-code")
          .with(
            query: { size: "300", format: "png" },
            headers: { "X-Api-Key" => "test-key" }
          )
          .to_return(
            status: 200,
            body: "fallback-qr-data",
            headers: { "content-type" => "image/png" }
          )
      end

      it "代替エンドポイントからQRコードを取得すること" do
        result = service.call(short_code: short_code)

        expect(result).to include(
          content_type: "image/png",
          data: "fallback-qr-data",
          format: "png"
        )
      end
    end

    context "両方のエンドポイントが失敗する場合" do
      before do
        stub_request(:get, "https://test.example.com/#{short_code}/qr-code")
          .to_return(status: 404)

        stub_request(:get, "https://test.example.com/rest/v3/short-urls/#{short_code}/qr-code")
          .to_return(status: 404)
      end

      it "Shlink::Errorを発生させること" do
        expect {
          service.call(short_code: short_code)
        }.to raise_error(Shlink::Error, /Unable to retrieve QR code/)
      end
    end

    context "ネットワークエラーが発生した場合" do
      before do
        stub_request(:get, "https://test.example.com/#{short_code}/qr-code")
          .to_raise(Faraday::ConnectionFailed.new("接続失敗"))
      end

      it "Shlink::Errorを発生させること" do
        expect {
          service.call(short_code: short_code)
        }.to raise_error(Shlink::Error, /HTTP error/)
      end
    end
  end

  describe "#call!" do
    it "callメソッドと同じ動作をすること" do
      stub_request(:get, "https://test.example.com/#{short_code}/qr-code")
        .to_return(
          status: 200,
          body: "test-data",
          headers: { "content-type" => "image/png" }
        )

      result = service.call!(short_code: short_code)
      expect(result[:data]).to eq("test-data")
    end
  end

  describe "デフォルトパラメータ" do
    it "デフォルトのサイズは300であること" do
      stub_request(:get, "https://test.example.com/#{short_code}/qr-code")
        .with(query: hash_including({ size: "300" }))
        .to_return(status: 200, body: "data", headers: { "content-type" => "image/png" })

      service.call(short_code: short_code)
    end

    it "デフォルトのフォーマットはpngであること" do
      stub_request(:get, "https://test.example.com/#{short_code}/qr-code")
        .with(query: hash_including({ format: "png" }))
        .to_return(status: 200, body: "data", headers: { "content-type" => "image/png" })

      service.call(short_code: short_code)
    end
  end
end
