require 'rails_helper'

RSpec.describe EditShortUrlForm, type: :model do
  let(:short_url) do
    build(:short_url,
      short_code: 'test123',
      title: 'Test Title',
      long_url: 'https://example.com',
      valid_until: 1.day.from_now,
      max_visits: 100,
      tags: [ 'tag1', 'tag2' ].to_json
    )
  end

  describe '.from_short_url' do
    it 'ShortUrlモデルから正しく初期化される' do
      form = described_class.from_short_url(short_url)

      expect(form.short_code).to eq('test123')
      expect(form.title).to eq('Test Title')
      expect(form.long_url).to eq('https://example.com')
      expect(form.valid_until).to eq(short_url.valid_until)
      expect(form.max_visits).to eq('100')
      expect(form.tags).to eq('tag1, tag2')
      expect(form.custom_slug).to eq('test123')
    end
  end

  describe 'バリデーション' do
    let(:form) { described_class.new(short_code: 'test123') }

    describe 'long_url' do
      it '有効なURLの場合はエラーにならない' do
        form.long_url = 'https://example.com'
        form.valid?
        expect(form.errors[:long_url]).to be_empty
      end

      it '無効なURLの場合はエラーになる' do
        form.long_url = 'invalid-url'
        form.valid?
        expect(form.errors[:long_url]).to be_present
      end

      it '空の場合はエラーにならない' do
        form.long_url = ''
        form.valid?
        expect(form.errors[:long_url]).to be_empty
      end
    end

    describe 'valid_until' do
      it '未来の日時の場合はエラーにならない' do
        form.valid_until = 1.day.from_now
        form.valid?
        expect(form.errors[:valid_until]).to be_empty
      end

      it '過去の日時の場合はエラーになる' do
        form.valid_until = 1.day.ago
        form.valid?
        expect(form.errors[:valid_until]).to be_present
      end

      it '空の場合はエラーにならない' do
        form.valid_until = nil
        form.valid?
        expect(form.errors[:valid_until]).to be_empty
      end
    end

    describe 'max_visits' do
      it '正の整数の場合はエラーにならない' do
        form.max_visits = 100
        form.valid?
        expect(form.errors[:max_visits]).to be_empty
      end

      it '0以下の場合はエラーになる' do
        form.max_visits = 0
        form.valid?
        expect(form.errors[:max_visits]).to be_present
      end

      it '小数の場合はエラーになる' do
        form.max_visits = 10.5
        form.valid?
        expect(form.errors[:max_visits]).to be_present
      end

      it '空の場合はエラーにならない' do
        form.max_visits = nil
        form.valid?
        expect(form.errors[:max_visits]).to be_empty
      end
    end

    describe 'tags' do
      it '有効なタグの場合はエラーにならない' do
        form.tags = 'tag1, tag2, tag3'
        form.valid?
        expect(form.errors[:tags]).to be_empty
      end

      it '10個を超えるタグの場合はエラーになる' do
        form.tags = (1..11).map { |i| "tag#{i}" }.join(', ')
        form.valid?
        expect(form.errors[:tags]).to be_present
        expect(form.errors[:tags].first).to include('最大10個まで')
      end

      it '20文字を超えるタグの場合はエラーになる' do
        form.tags = 'a' * 21
        form.valid?
        expect(form.errors[:tags]).to be_present
        expect(form.errors[:tags].first).to include('20文字以内')
      end

      it '空の場合はエラーにならない' do
        form.tags = ''
        form.valid?
        expect(form.errors[:tags]).to be_empty
      end
    end

    describe 'custom_slug' do
      it '有効なカスタムスラッグの場合はエラーにならない' do
        form.custom_slug = 'valid-slug_123'
        form.valid?
        expect(form.errors[:custom_slug]).to be_empty
      end

      it '無効な文字を含む場合はエラーになる' do
        form.custom_slug = 'invalid@slug'
        form.valid?
        expect(form.errors[:custom_slug]).to be_present
        expect(form.errors[:custom_slug].first).to include('英数字、ハイフン、アンダースコア')
      end

      it '3文字未満の場合はエラーになる' do
        form.custom_slug = 'ab'
        form.valid?
        expect(form.errors[:custom_slug]).to be_present
        expect(form.errors[:custom_slug].first).to include('3文字以上')
      end

      it '50文字を超える場合はエラーになる' do
        form.custom_slug = 'a' * 51
        form.valid?
        expect(form.errors[:custom_slug]).to be_present
        expect(form.errors[:custom_slug].first).to include('50文字以内')
      end

      it '空の場合はエラーにならない' do
        form.custom_slug = ''
        form.valid?
        expect(form.errors[:custom_slug]).to be_empty
      end
    end
  end

  describe '#tags_array' do
    let(:form) { described_class.new }

    it 'カンマ区切りの文字列を配列に変換する' do
      form.tags = 'tag1, tag2, tag3'
      expect(form.tags_array).to eq([ 'tag1', 'tag2', 'tag3' ])
    end

    it '重複を除去する' do
      form.tags = 'tag1, tag2, tag1'
      expect(form.tags_array).to eq([ 'tag1', 'tag2' ])
    end

    it '空白を除去する' do
      form.tags = ' tag1 ,  tag2  , tag3 '
      expect(form.tags_array).to eq([ 'tag1', 'tag2', 'tag3' ])
    end

    it '空のタグを除去する' do
      form.tags = 'tag1, , tag2'
      expect(form.tags_array).to eq([ 'tag1', 'tag2' ])
    end

    it '空の場合は空配列を返す' do
      form.tags = ''
      expect(form.tags_array).to eq([])
    end
  end

  describe '#update_params' do
    let(:form) do
      described_class.new(
        short_code: 'original',
        title: 'New Title',
        long_url: 'https://example.com',
        tags: 'tag1, tag2',
        valid_until: 1.day.from_now,
        max_visits: 100,
        custom_slug: 'new-slug'
      )
    end

    it '更新用のパラメータを正しく生成する' do
      params = form.update_params

      expect(params[:title]).to eq('New Title')
      expect(params[:long_url]).to eq('https://example.com')
      expect(params[:tags]).to eq([ 'tag1', 'tag2' ])
      expect(params[:valid_until]).to eq(form.valid_until)
      expect(params[:max_visits]).to eq(100)
      expect(params[:custom_slug]).to eq('new-slug')
    end

    it '空の値を除外する' do
      form.title = ''
      form.long_url = nil

      params = form.update_params

      expect(params).not_to have_key(:title)
      expect(params).not_to have_key(:long_url)
    end

    it 'カスタムスラッグが元のshort_codeと同じ場合は除外する' do
      form.custom_slug = 'original'

      params = form.update_params

      expect(params).not_to have_key(:custom_slug)
    end

    it 'タグが空の場合はnilを設定する' do
      form.tags = ''

      params = form.update_params

      expect(params[:tags]).to be_nil
    end
  end
end
