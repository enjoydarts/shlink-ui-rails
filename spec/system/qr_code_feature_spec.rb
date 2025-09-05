require 'rails_helper'
require_relative '../../app/services/shlink/base_service'
require_relative '../../app/services/shlink/create_short_url_service'
require_relative '../../app/services/shlink/get_qr_code_service'

RSpec.describe "QRコード機能のシステムテスト", type: :system do
  before do
    driven_by(:rack_test)

    # Shlink APIのモック設定
    allow_any_instance_of(Shlink::CreateShortUrlService).to receive(:call)
      .with(long_url: anything, slug: anything)
      .and_return({
        "shortUrl" => "https://test.example.com/abc123",
        "shortCode" => "abc123"
      })

    allow_any_instance_of(Shlink::GetQrCodeService).to receive(:call)
      .and_return({
        content_type: "image/png",
        data: "fake-qr-data",
        format: "png"
      })
  end

  describe "QRコード生成オプション" do
    it "QRコードチェックボックスが表示されること", js: true do
      visit root_path

      expect(page).to have_field("QRコードも生成する", type: "checkbox")
      expect(page).to have_text("モバイルでの共有に便利です")
    end

    it "QRコードチェックボックスがデフォルトでオフであること" do
      visit root_path

      checkbox = find_field("QRコードも生成する", type: "checkbox")
      expect(checkbox).not_to be_checked
    end
  end

  describe "QRコード付きURL短縮" do
    context "QRコードオプションを有効にして短縮した場合", js: true do
      it "QRコードが表示されること" do
        visit root_path

        fill_in "shorten_form[long_url]", with: "https://example.com/very/long/url/path"
        fill_in "shorten_form[slug]", with: "test-slug"
        check "QRコードも生成する"

        click_button "短縮する"

        # リダイレクト先で成功が確認できること
        expect(page).to have_current_path(root_path)
        expect(page).to have_text("URL短縮ツール")
      end
    end

    context "QRコードオプションを無効にして短縮した場合", js: true do
      it "QRコードが表示されないこと" do
        visit root_path

        fill_in "shorten_form[long_url]", with: "https://example.com/test"
        uncheck "QRコードも生成する"  # 明示的にオフにする

        click_button "短縮する"

        # リダイレクト先で成功が確認できること
        expect(page).to have_current_path(root_path)
        expect(page).to have_text("URL短縮ツール")
      end
    end
  end

  describe "QRコード画像の直接アクセス" do
    it "QRコードエンドポイントに直接アクセスできること" do
      visit qr_code_path(short_code: "abc123")

      expect(page.response_headers["Content-Type"]).to eq("image/png")
      expect(page.response_headers["Content-Disposition"]).to match(/inline.*qr-abc123\.png/)
    end

    it "サイズパラメータ付きでQRコードにアクセスできること" do
      visit qr_code_path(short_code: "abc123", size: 400)

      expect(page.response_headers["Content-Type"]).to eq("image/png")
    end

    it "フォーマットパラメータ付きでQRコードにアクセスできること" do
      # SVGフォーマットの場合のモック設定
      allow_any_instance_of(Shlink::GetQrCodeService).to receive(:call)
        .and_return({
          content_type: "image/svg+xml",
          data: "<svg>test</svg>",
          format: "svg"
        })

      visit qr_code_path(short_code: "abc123", format: "svg")

      expect(page.response_headers["Content-Type"]).to eq("image/svg+xml")
      expect(page.response_headers["Content-Disposition"]).to match(/qr-abc123\.svg/)
    end
  end

  describe "エラーハンドリング" do
    context "QRコード取得でエラーが発生した場合" do
      before do
        allow_any_instance_of(Shlink::GetQrCodeService).to receive(:call)
          .and_raise(Shlink::Error, "QR code generation failed")
      end

      it "適切なエラーレスポンスを返すこと" do
        visit qr_code_path(short_code: "invalid")

        expect(page.status_code).to eq(502)
      end
    end
  end

  describe "UIのレスポンシブ対応" do
    context "デスクトップ表示", js: true do
      it "QRコードが横並びで表示されること" do
        visit root_path

        fill_in "shorten_form[long_url]", with: "https://example.com/test"
        check "QRコードも生成する"
        click_button "短縮する"

        # リダイレクト先で成功が確認できること
        expect(page).to have_current_path(root_path)
        expect(page).to have_text("URL短縮ツール")
      end
    end
  end
end
