require 'rails_helper'

RSpec.describe ShortenForm, type: :model do
  subject { described_class.new(attributes) }

  describe 'バリデーション' do
    context '有効な属性の場合' do
      let(:attributes) { { long_url: 'https://example.com/very/long/url' } }

      it '有効である' do
        expect(subject).to be_valid
      end

      context 'デバイス別リダイレクトが有効な場合' do
        let(:attributes) do
          {
            long_url: 'https://example.com/very/long/url',
            device_redirects_enabled: true,
            android_url: 'https://play.google.com/store/apps/details?id=example',
            ios_url: 'https://apps.apple.com/app/id123456789'
          }
        end

        it '有効である' do
          expect(subject).to be_valid
        end
      end
    end

    context '無効な属性の場合' do
      context 'long_urlが空白の場合' do
        let(:attributes) { { long_url: '' } }

        it '無効である' do
          expect(subject).not_to be_valid
          expect(subject.errors[:long_url]).to include('を入力してください')
        end
      end

      context 'long_urlがnilの場合' do
        let(:attributes) { { long_url: nil } }

        it '無効である' do
          expect(subject).not_to be_valid
          expect(subject.errors[:long_url]).to include('を入力してください')
        end
      end

      context 'long_urlが有効なURLでない場合' do
        let(:attributes) { { long_url: 'not-a-url' } }

        it '無効である' do
          expect(subject).not_to be_valid
          expect(subject.errors[:long_url]).to include('は無効なURLです')
        end
      end

      context 'long_urlがhttp/httpsで始まらない場合' do
        let(:attributes) { { long_url: 'ftp://example.com' } }

        it '無効である' do
          expect(subject).not_to be_valid
          expect(subject.errors[:long_url]).to include('は無効なURLです')
        end
      end

      context 'デバイス別リダイレクトが無効な場合' do
        context 'デバイス別リダイレクトが有効だがURLが未設定の場合' do
          let(:attributes) do
            {
              long_url: 'https://example.com/very/long/url',
              device_redirects_enabled: true
            }
          end

          it '無効である' do
            expect(subject).not_to be_valid
            expect(subject.errors[:base]).to include('デバイス別リダイレクトを有効にする場合は、少なくとも1つのデバイス用URLを設定してください')
          end
        end

        context 'デバイス用URLの形式が無効な場合' do
          let(:attributes) do
            {
              long_url: 'https://example.com/very/long/url',
              device_redirects_enabled: true,
              android_url: 'invalid-url'
            }
          end

          it '無効である' do
            expect(subject).not_to be_valid
            expect(subject.errors[:android_url]).to be_present
          end
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
          expect(subject.errors[:long_url]).to include('は無効なURLです')
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
        expect(subject.errors[:valid_until]).to include('は現在時刻より後の時間を入力してください')
      end
    end

    context 'valid_untilが現在時刻（JST）より少し前の場合' do
      let(:past_time) { 1.minute.ago }
      let(:attributes) { { long_url: 'https://example.com', valid_until: past_time } }

      it '無効である' do
        expect(subject).not_to be_valid
        expect(subject.errors[:valid_until]).to include('は現在時刻より後の時間を入力してください')
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
        expect(subject.errors[:max_visits]).to include('は0より大きい値を入力してください')
      end
    end

    context 'max_visitsが負の数の場合' do
      let(:attributes) { { long_url: 'https://example.com', max_visits: -1 } }

      it '無効である' do
        expect(subject).not_to be_valid
        expect(subject.errors[:max_visits]).to include('は0より大きい値を入力してください')
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

  describe 'tagsのバリデーション' do
    context 'tagsが空の場合' do
      let(:attributes) { { long_url: 'https://example.com', tags: '' } }

      it '有効である（tagsは任意）' do
        expect(subject).to be_valid
      end
    end

    context 'tagsがnilの場合' do
      let(:attributes) { { long_url: 'https://example.com', tags: nil } }

      it '有効である（tagsは任意）' do
        expect(subject).to be_valid
      end
    end

    context '有効なタグの場合' do
      let(:attributes) { { long_url: 'https://example.com', tags: 'tag1, tag2, tag3' } }

      it '有効である' do
        expect(subject).to be_valid
      end
    end

    context '10個以下のタグの場合' do
      let(:attributes) { { long_url: 'https://example.com', tags: (1..10).map { |i| "tag#{i}" }.join(', ') } }

      it '有効である' do
        expect(subject).to be_valid
      end
    end

    context '11個以上のタグの場合' do
      let(:attributes) { { long_url: 'https://example.com', tags: (1..11).map { |i| "tag#{i}" }.join(', ') } }

      it '無効である' do
        expect(subject).not_to be_valid
        expect(subject.errors[:tags]).to include('タグは最大10個まで設定できます')
      end
    end

    context '20文字以内のタグの場合' do
      let(:attributes) { { long_url: 'https://example.com', tags: 'a' * 20 } }

      it '有効である' do
        expect(subject).to be_valid
      end
    end

    context '21文字以上のタグが含まれる場合' do
      let(:attributes) { { long_url: 'https://example.com', tags: 'a' * 21 } }

      it '無効である' do
        expect(subject).not_to be_valid
        expect(subject.errors[:tags]).to include('各タグは20文字以内で入力してください')
      end
    end
  end

  describe '#tags_array' do
    subject { described_class.new(attributes).tags_array }

    context 'カンマ区切りのタグの場合' do
      let(:attributes) { { tags: 'tag1, tag2, tag3' } }

      it 'タグの配列を返す' do
        expect(subject).to eq([ 'tag1', 'tag2', 'tag3' ])
      end
    end

    context '前後にスペースがあるタグの場合' do
      let(:attributes) { { tags: ' tag1 , tag2 , tag3 ' } }

      it 'スペースを除去したタグの配列を返す' do
        expect(subject).to eq([ 'tag1', 'tag2', 'tag3' ])
      end
    end

    context '重複するタグの場合' do
      let(:attributes) { { tags: 'tag1, tag2, tag1, tag3' } }

      it '重複を除去したタグの配列を返す' do
        expect(subject).to eq([ 'tag1', 'tag2', 'tag3' ])
      end
    end

    context '空のタグが含まれる場合' do
      let(:attributes) { { tags: 'tag1, , tag2, , tag3' } }

      it '空のタグを除去したタグの配列を返す' do
        expect(subject).to eq([ 'tag1', 'tag2', 'tag3' ])
      end
    end

    context 'tagsが空の場合' do
      let(:attributes) { { tags: '' } }

      it '空の配列を返す' do
        expect(subject).to eq([])
      end
    end

    context 'tagsがnilの場合' do
      let(:attributes) { { tags: nil } }

      it '空の配列を返す' do
        expect(subject).to eq([])
      end
    end
  end

  describe '#device_redirect_rules' do
    subject { form.device_redirect_rules }

    context 'デバイス別リダイレクトが無効な場合' do
      let(:form) do
        described_class.new(
          long_url: 'https://example.com',
          device_redirects_enabled: false,
          android_url: 'https://play.google.com/store/apps/details?id=example'
        )
      end

      it '空の配列を返す' do
        expect(subject).to eq([])
      end
    end

    context 'デバイス別リダイレクトが有効な場合' do
      let(:form) do
        described_class.new(
          long_url: 'https://example.com',
          device_redirects_enabled: true,
          android_url: 'https://play.google.com/store/apps/details?id=example',
          ios_url: 'https://apps.apple.com/app/id123456789',
          desktop_url: 'https://example.com/desktop'
        )
      end

      it '正しいリダイレクトルールを返す' do
        expected_rules = [
          {
            longUrl: 'https://play.google.com/store/apps/details?id=example',
            conditions: [
              { type: "device", matchValue: "android", matchKey: nil }
            ]
          },
          {
            longUrl: 'https://apps.apple.com/app/id123456789',
            conditions: [
              { type: "device", matchValue: "ios", matchKey: nil }
            ]
          },
          {
            longUrl: 'https://example.com/desktop',
            conditions: [
              { type: "device", matchValue: "desktop", matchKey: nil }
            ]
          }
        ]
        expect(subject).to eq(expected_rules)
      end
    end

    context '一部のデバイス用URLのみ設定された場合' do
      let(:form) do
        described_class.new(
          long_url: 'https://example.com',
          device_redirects_enabled: true,
          android_url: 'https://play.google.com/store/apps/details?id=example'
        )
      end

      it '設定されたデバイスのルールのみ返す' do
        expected_rules = [
          {
            longUrl: 'https://play.google.com/store/apps/details?id=example',
            conditions: [
              { type: "device", matchValue: "android", matchKey: nil }
            ]
          }
        ]
        expect(subject).to eq(expected_rules)
      end
    end
  end
end
