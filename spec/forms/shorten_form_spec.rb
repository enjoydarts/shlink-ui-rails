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
    let(:attributes) { { long_url: 'https://example.com', slug: 'custom-slug', valid_until: 1.day.from_now, max_visits: 100 } }

    it 'long_url属性を持つ' do
      expect(subject.long_url).to eq('https://example.com')
    end

    it 'slug属性を持つ' do
      expect(subject.slug).to eq('custom-slug')
    end

    it 'valid_until属性を持つ' do
      expect(subject.valid_until).to be_within(1.second).of(1.day.from_now)
    end

    it 'max_visits属性を持つ' do
      expect(subject.max_visits).to eq(100)
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

  describe 'valid_untilのバリデーション（JST対応）' do
    around do |example|
      Time.use_zone('Asia/Tokyo') do
        example.run
      end
    end

    context 'valid_untilが空の場合' do
      let(:attributes) { { long_url: 'https://example.com', valid_until: nil } }

      it '有効である（valid_untilは任意）' do
        expect(subject).to be_valid
      end
    end

    context 'valid_untilが現在時刻（JST）より後の場合' do
      let(:attributes) { { long_url: 'https://example.com', valid_until: 1.hour.from_now } }

      it '有効である' do
        expect(subject).to be_valid
      end
    end

    context 'valid_untilが現在時刻（JST）より前の場合' do
      let(:attributes) { { long_url: 'https://example.com', valid_until: 1.hour.ago } }

      it '無効である' do
        expect(subject).not_to be_valid
        expect(subject.errors[:valid_until]).to include(a_string_matching(/must be greater than/))
      end
    end

    context 'valid_untilが現在時刻（JST）より少し前の場合' do
      let(:past_time) { 1.minute.ago }
      let(:attributes) { { long_url: 'https://example.com', valid_until: past_time } }

      it '無効である' do
        expect(subject).not_to be_valid
        expect(subject.errors[:valid_until]).to include(a_string_matching(/must be greater than/))
      end
    end
  end

  describe 'max_visitsのバリデーション' do
    context 'max_visitsが空の場合' do
      let(:attributes) { { long_url: 'https://example.com', max_visits: nil } }

      it '有効である（max_visitsは任意）' do
        expect(subject).to be_valid
      end
    end

    context 'max_visitsが正の整数の場合' do
      let(:attributes) { { long_url: 'https://example.com', max_visits: 100 } }

      it '有効である' do
        expect(subject).to be_valid
      end
    end

    context 'max_visitsが0の場合' do
      let(:attributes) { { long_url: 'https://example.com', max_visits: 0 } }

      it '無効である' do
        expect(subject).not_to be_valid
        expect(subject.errors[:max_visits]).to include('must be greater than 0')
      end
    end

    context 'max_visitsが負の数の場合' do
      let(:attributes) { { long_url: 'https://example.com', max_visits: -1 } }

      it '無効である' do
        expect(subject).not_to be_valid
        expect(subject.errors[:max_visits]).to include('must be greater than 0')
      end
    end

    context 'max_visitsが小数の場合' do
      let(:attributes) { { long_url: 'https://example.com', max_visits: 10.5 } }

      it '小数は整数に変換されるため有効である' do
        expect(subject).to be_valid
        expect(subject.max_visits).to eq(10)
      end
    end
  end
end
