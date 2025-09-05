require 'rails_helper'

RSpec.describe ShortenForm, "QRコード機能" do
  describe "QRコードオプション属性" do
    it "include_qr_code属性が定義されていること" do
      form = ShortenForm.new
      expect(form).to respond_to(:include_qr_code)
      expect(form).to respond_to(:include_qr_code=)
    end

    it "デフォルト値がfalseであること" do
      form = ShortenForm.new
      expect(form.include_qr_code).to be false
    end

    it "boolean値を受け入れること" do
      form = ShortenForm.new(include_qr_code: true)
      expect(form.include_qr_code).to be true

      form = ShortenForm.new(include_qr_code: false)
      expect(form.include_qr_code).to be false
    end

    it "文字列のboolean値を受け入れること" do
      form = ShortenForm.new(include_qr_code: "1")
      expect(form.include_qr_code).to be true

      form = ShortenForm.new(include_qr_code: "0")
      expect(form.include_qr_code).to be false

      form = ShortenForm.new(include_qr_code: "true")
      expect(form.include_qr_code).to be true

      form = ShortenForm.new(include_qr_code: "false")
      expect(form.include_qr_code).to be false
    end
  end

  describe "QRコードオプション付きフォーム検証" do
    context "有効なパラメータとQRコードオプション" do
      let(:valid_attributes) do
        {
          long_url: "https://example.com/test",
          slug: "test-slug",
          include_qr_code: true
        }
      end

      it "フォームが有効であること" do
        form = ShortenForm.new(valid_attributes)
        expect(form.valid?).to be true
        expect(form.include_qr_code).to be true
      end
    end

    context "QRコードオプションが無効なURL検証に影響しないこと" do
      let(:invalid_attributes) do
        {
          long_url: "invalid-url",
          slug: "test-slug",
          include_qr_code: true
        }
      end

      it "URL検証エラーが正常に発生すること" do
        form = ShortenForm.new(invalid_attributes)
        expect(form.valid?).to be false
        expect(form.errors[:long_url]).to be_present
        expect(form.include_qr_code).to be true  # QRコードオプションは保持される
      end
    end
  end

  describe "フォーム属性の組み合わせテスト" do
    it "すべての属性が正常に設定されること" do
      form = ShortenForm.new(
        long_url: "https://example.com/very/long/path",
        slug: "custom-slug",
        include_qr_code: true
      )

      expect(form.long_url).to eq("https://example.com/very/long/path")
      expect(form.slug).to eq("custom-slug")
      expect(form.include_qr_code).to be true
      expect(form.valid?).to be true
    end

    it "QRコードオプションなしでも正常に動作すること" do
      form = ShortenForm.new(
        long_url: "https://example.com/test",
        slug: "test"
      )

      expect(form.long_url).to eq("https://example.com/test")
      expect(form.slug).to eq("test")
      expect(form.include_qr_code).to be false  # デフォルト値
      expect(form.valid?).to be true
    end
  end
end
