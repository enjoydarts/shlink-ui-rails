require 'rails_helper'

RSpec.describe ShortenForm, type: :model do
  subject { described_class.new(attributes) }

  describe 'バリデーション' do
    context '有効な属性の場合' do
      let(:attributes) { { long_url: 'https://example.com/very/long/url' } }

      it '有効である' do
        expect(subject).to be_valid
      end
    end

    context '無効な属性の場合' do
      context 'long_urlが空白の場合' do
        let(:attributes) { { long_url: '' } }

        it '無効である' do
          expect(subject).not_to be_valid
          expect(subject.errors[:long_url]).to include("can't be blank")
        end
      end

      context 'long_urlがnilの場合' do
        let(:attributes) { { long_url: nil } }

        it '無効である' do
          expect(subject).not_to be_valid
          expect(subject.errors[:long_url]).to include("can't be blank")
        end
      end

      context 'long_urlが有効なURLでない場合' do
        let(:attributes) { { long_url: 'not-a-url' } }

        it '無効である' do
          expect(subject).not_to be_valid
          expect(subject.errors[:long_url]).to include('is invalid')
        end
      end

      context 'long_urlがhttp/httpsで始まらない場合' do
        let(:attributes) { { long_url: 'ftp://example.com' } }

        it '無効である' do
          expect(subject).not_to be_valid
          expect(subject.errors[:long_url]).to include('is invalid')
        end
      end
    end
  end

  describe '属性' do
    let(:attributes) { { long_url: 'https://example.com', slug: 'custom-slug' } }

    it 'long_url属性を持つ' do
      expect(subject.long_url).to eq('https://example.com')
    end

    it 'slug属性を持つ' do
      expect(subject.slug).to eq('custom-slug')
    end
  end

  describe '有効なURL形式' do
    [
      'https://example.com',
      'http://example.com',
      'https://www.example.com/path/to/resource',
      'https://subdomain.example.com',
      'https://example.com:8080',
      'https://example.com/path?query=value&other=param',
      'https://example.com/path#fragment'
    ].each do |url|
      context "URL: #{url} の場合" do
        let(:attributes) { { long_url: url } }

        it '有効である' do
          expect(subject).to be_valid
        end
      end
    end
  end

  describe '無効なURL形式' do
    [
      'example.com',
      'ftp://example.com',
      'mailto:test@example.com',
      'javascript:alert("xss")',
      'data:text/html,<script>alert("xss")</script>',
      'file:///etc/passwd'
    ].each do |url|
      context "URL: #{url} の場合" do
        let(:attributes) { { long_url: url } }

        it '無効である' do
          expect(subject).not_to be_valid
          expect(subject.errors[:long_url]).to include('is invalid')
        end
      end
    end
  end

  describe 'slugのバリデーション' do
    context 'slugが空文字の場合' do
      let(:attributes) { { long_url: 'https://example.com', slug: '' } }

      it '有効である（空のslugは許可される）' do
        expect(subject).to be_valid
      end
    end

    context 'slugがnilの場合' do
      let(:attributes) { { long_url: 'https://example.com', slug: nil } }

      it '有効である（nilのslugは許可される）' do
        expect(subject).to be_valid
      end
    end

    context 'slugが提供された場合' do
      let(:attributes) { { long_url: 'https://example.com', slug: 'my-custom-slug' } }

      it '有効である' do
        expect(subject).to be_valid
      end
    end
  end
end
