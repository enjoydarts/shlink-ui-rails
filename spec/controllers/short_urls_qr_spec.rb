require 'rails_helper'

RSpec.describe ShortUrlsController, "QRコード機能" do
  let!(:user) { create(:user) }

  before do
    sign_in user, scope: :user
  end

  describe "GET #qr_code" do
    let(:short_code) { "abc123" }
    let(:fake_qr_data) { "fake-qr-image-binary-data" }

    before do
      allow_any_instance_of(Shlink::GetQrCodeService).to receive(:call)
        .and_return({
          content_type: "image/png",
          data: fake_qr_data,
          format: "png"
        })
    end

    context "有効なshort_codeが指定された場合" do
      it "QRコード画像を返すこと" do
        get :qr_code, params: { short_code: short_code }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq("image/png")
        expect(response.body).to eq(fake_qr_data)
        expect(response.headers["Content-Disposition"]).to match(/inline.*qr-#{short_code}\.png/)
      end
    end

    context "サイズパラメータが指定された場合" do
      it "指定されたサイズでQRコードを取得すること" do
        expect_any_instance_of(Shlink::GetQrCodeService).to receive(:call)
          .with(short_code: short_code, size: 400, format: "png")
          .and_return({
            content_type: "image/png",
            data: fake_qr_data,
            format: "png"
          })

        get :qr_code, params: { short_code: short_code, size: "400" }

        expect(response).to have_http_status(:ok)
      end
    end

    context "フォーマットパラメータが指定された場合" do
      before do
        allow_any_instance_of(Shlink::GetQrCodeService).to receive(:call)
          .and_return({
            content_type: "image/svg+xml",
            data: "<svg>fake-svg</svg>",
            format: "svg"
          })
      end

      it "指定されたフォーマットでQRコードを取得すること" do
        expect_any_instance_of(Shlink::GetQrCodeService).to receive(:call)
          .with(short_code: short_code, size: 300, format: "svg")

        get :qr_code, params: { short_code: short_code, format: "svg" }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq("image/svg+xml")
        expect(response.headers["Content-Disposition"]).to match(/qr-#{short_code}\.svg/)
      end
    end

    context "Shlink APIエラーが発生した場合" do
      before do
        allow_any_instance_of(Shlink::GetQrCodeService).to receive(:call)
          .and_raise(Shlink::Error, "QR code not found")
      end

      it "502エラーを返すこと" do
        get :qr_code, params: { short_code: short_code }

        expect(response).to have_http_status(:bad_gateway)
        expect(JSON.parse(response.body)).to include("error" => "QR code not found")
      end
    end
  end

  describe "POST #create QRコード統合機能" do
    let(:valid_params) do
      {
        shorten_form: {
          long_url: "https://example.com/very/long/url",
          slug: "custom",
          include_qr_code: "1"
        }
      }
    end

    before do
      mock_service = instance_double(Shlink::CreateShortUrlService)
      allow(Shlink::CreateShortUrlService).to receive(:new).and_return(mock_service)
      allow(mock_service).to receive(:call)
        .and_return({
          "shortUrl" => "https://test.example.com/custom",
          "shortCode" => "custom"
        })
    end

    context "QRコード生成が要求された場合" do
      it "@resultにqr_code_urlが含まれること" do
        post :create, params: valid_params, xhr: true

        expect(assigns(:result)).to include(:qr_code_url)
        expect(assigns(:result)[:qr_code_url]).to eq(qr_code_path(short_code: "custom"))
      end
    end

    context "QRコード生成が要求されていない場合" do
      let(:params_without_qr) do
        {
          shorten_form: {
            long_url: "https://example.com/very/long/url",
            slug: "custom",
            include_qr_code: "0"
          }
        }
      end

      it "@resultにqr_code_urlが含まれないこと" do
        post :create, params: params_without_qr, format: :turbo_stream

        expect(assigns(:result)).not_to include(:qr_code_url)
      end
    end
  end
end
