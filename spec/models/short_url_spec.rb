require 'rails_helper'

RSpec.describe ShortUrl, type: :model do
  describe 'アソシエーション' do
    it { should belong_to(:user) }
  end

  describe 'バリデーション' do
    subject { build(:short_url) }

    it { should validate_presence_of(:short_code) }
    it { should validate_uniqueness_of(:short_code).case_insensitive }
    it { should validate_presence_of(:short_url) }
    it { should validate_presence_of(:long_url) }
    it { should validate_presence_of(:visit_count) }
    it { should validate_numericality_of(:visit_count).is_greater_than_or_equal_to(0) }
    it { should validate_presence_of(:date_created) }
  end

  describe 'スコープ' do
    let(:user) { create(:user) }
    let!(:old_url) { create(:short_url, user: user, date_created: 2.days.ago) }
    let!(:new_url) { create(:short_url, user: user, date_created: 1.day.ago) }
    let!(:newest_url) { create(:short_url, user: user, date_created: Time.current) }

    describe '.recent' do
      it '作成日時の降順で返すこと' do
        expect(ShortUrl.by_user(user).recent.to_a).to eq([ newest_url, new_url, old_url ])
      end
    end

    describe '.by_user' do
      let(:other_user) { create(:user) }
      let!(:other_url) { create(:short_url, user: other_user) }

      it '指定されたユーザーのURLのみ返すこと' do
        expect(ShortUrl.by_user(user)).to contain_exactly(old_url, new_url, newest_url)
        expect(ShortUrl.by_user(user)).not_to include(other_url)
      end
    end
  end

  describe 'タグ管理' do
    let(:short_url) { create(:short_url) }

    describe '#tags_array' do
      context 'タグがある場合' do
        before { short_url.update(tags: [ "tag1", "tag2" ].to_json) }

        it 'タグの配列を返すこと' do
          expect(short_url.tags_array).to eq([ "tag1", "tag2" ])
        end
      end

      context 'タグがない場合' do
        before { short_url.update(tags: nil) }

        it '空の配列を返すこと' do
          expect(short_url.tags_array).to eq([])
        end
      end

      context '不正なJSONの場合' do
        before { short_url.update_column(:tags, "invalid json") }

        it '空の配列を返すこと' do
          expect(short_url.tags_array).to eq([])
        end
      end
    end

    describe '#tags_array=' do
      it 'タグをJSONとして保存すること' do
        short_url.tags_array = [ "new_tag1", "new_tag2" ]
        expect(short_url.tags).to eq([ "new_tag1", "new_tag2" ].to_json)
      end
    end
  end

  describe 'メタデータ管理' do
    let(:short_url) { create(:short_url) }

    describe '#meta_hash' do
      context 'メタデータがある場合' do
        before { short_url.update(meta: { "title" => "Test", "description" => "Test URL" }.to_json) }

        it 'メタデータのハッシュを返すこと' do
          expect(short_url.meta_hash).to eq({ "title" => "Test", "description" => "Test URL" })
        end
      end

      context 'メタデータがない場合' do
        before { short_url.update(meta: nil) }

        it '空のハッシュを返すこと' do
          expect(short_url.meta_hash).to eq({})
        end
      end

      context '不正なJSONの場合' do
        before { short_url.update_column(:meta, "invalid json") }

        it '空のハッシュを返すこと' do
          expect(short_url.meta_hash).to eq({})
        end
      end
    end

    describe '#meta_hash=' do
      it 'メタデータをJSONとして保存すること' do
        short_url.meta_hash = { "new_title" => "New Test" }
        expect(short_url.meta).to eq({ "new_title" => "New Test" }.to_json)
      end
    end
  end

  describe '有効期限' do
    describe '#has_expiration?' do
      it '有効期限がある場合はtrueを返すこと' do
        short_url = create(:short_url, :with_expiration)
        expect(short_url.has_expiration?).to be true
      end

      it '有効期限がない場合はfalseを返すこと' do
        short_url = create(:short_url)
        expect(short_url.has_expiration?).to be false
      end
    end

    describe '#expired?' do
      it '有効期限切れの場合はtrueを返すこと' do
        short_url = create(:short_url, :expired)
        expect(short_url.expired?).to be true
      end

      it '有効期限内の場合はfalseを返すこと' do
        short_url = create(:short_url, :with_expiration)
        expect(short_url.expired?).to be false
      end

      it '有効期限がない場合はfalseを返すこと' do
        short_url = create(:short_url)
        expect(short_url.expired?).to be false
      end
    end
  end

  describe '訪問制限' do
    describe '#has_visit_limit?' do
      it '訪問制限がある場合はtrueを返すこと' do
        short_url = create(:short_url, :with_visit_limit)
        expect(short_url.has_visit_limit?).to be true
      end

      it '訪問制限がない場合はfalseを返すこと' do
        short_url = create(:short_url)
        expect(short_url.has_visit_limit?).to be false
      end
    end

    describe '#remaining_visits' do
      context '訪問制限がある場合' do
        let(:short_url) { create(:short_url, max_visits: 100, visit_count: 30) }

        it '残り訪問回数を返すこと' do
          expect(short_url.remaining_visits).to eq(70)
        end
      end

      context '訪問制限に達している場合' do
        let(:short_url) { create(:short_url, :visit_limit_reached) }

        it '0を返すこと' do
          expect(short_url.remaining_visits).to eq(0)
        end
      end

      context '訪問制限がない場合' do
        let(:short_url) { create(:short_url) }

        it 'nilを返すこと' do
          expect(short_url.remaining_visits).to be_nil
        end
      end
    end

    describe '#visit_limit_reached?' do
      it '訪問制限に達している場合はtrueを返すこと' do
        short_url = create(:short_url, :visit_limit_reached)
        expect(short_url.visit_limit_reached?).to be true
      end

      it '訪問制限に達していない場合はfalseを返すこと' do
        short_url = create(:short_url, :with_visit_limit)
        expect(short_url.visit_limit_reached?).to be false
      end

      it '訪問制限がない場合はfalseを返すこと' do
        short_url = create(:short_url)
        expect(short_url.visit_limit_reached?).to be false
      end
    end

    describe '#visit_display' do
      context '訪問制限がある場合' do
        let(:short_url) { create(:short_url, max_visits: 100, visit_count: 30) }

        it '現在の訪問数/最大訪問数の形式で返すこと' do
          expect(short_url.visit_display).to eq("30/100")
        end
      end

      context '訪問制限がない場合' do
        let(:short_url) { create(:short_url, visit_count: 50) }

        it '訪問数のみを返すこと' do
          expect(short_url.visit_display).to eq("50")
        end
      end
    end
  end

  describe '#active?' do
    it '有効期限切れでなく訪問制限に達していない場合はtrueを返すこと' do
      short_url = create(:short_url, :with_expiration, :with_visit_limit)
      expect(short_url.active?).to be true
    end

    it '有効期限切れの場合はfalseを返すこと' do
      short_url = create(:short_url, :expired)
      expect(short_url.active?).to be false
    end

    it '訪問制限に達している場合はfalseを返すこと' do
      short_url = create(:short_url, :visit_limit_reached)
      expect(short_url.active?).to be false
    end
  end
end
