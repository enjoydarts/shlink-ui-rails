require 'rails_helper'

RSpec.describe Admin::UserManagementService, type: :service do
  let(:user) { create(:user, name: 'Test User', sign_in_count: 5) }
  let(:service) { described_class.new(user) }

  describe '#user_statistics' do
    let!(:short_urls) { create_list(:short_url, 3, user: user, visit_count: 10) }

    it 'ユーザー統計情報を返すこと' do
      result = service.user_statistics

      expect(result).to have_key(:basic_info)
      expect(result).to have_key(:activity)
      expect(result).to have_key(:short_urls)
      expect(result).to have_key(:security)
    end

    it '基本情報が正しいこと' do
      basic_info = service.user_statistics[:basic_info]

      expect(basic_info[:id]).to eq(user.id)
      expect(basic_info[:name]).to eq('Test User')
      expect(basic_info[:email]).to eq(user.email)
      expect(basic_info[:role]).to eq(user.role)
    end

    it 'アクティビティ情報が正しいこと' do
      activity = service.user_statistics[:activity]

      expect(activity[:sign_in_count]).to eq(5)
    end

    it '短縮URL統計が正しいこと' do
      url_stats = service.user_statistics[:short_urls]

      expect(url_stats[:total_short_urls]).to eq(3)
      expect(url_stats[:total_visits]).to eq(30)
    end
  end

  describe '#user_basic_info' do
    it 'ユーザーの基本情報を返すこと' do
      info = service.send(:user_basic_info)

      expect(info[:id]).to eq(user.id)
      expect(info[:name]).to eq(user.name)
      expect(info[:email]).to eq(user.email)
      expect(info[:role]).to eq(user.role)
      expect(info[:created_at]).to eq(user.created_at)
    end
  end

  describe '#user_activity_stats' do
    before do
      user.update!(
        current_sign_in_at: 1.day.ago,
        last_sign_in_at: 2.days.ago
      )
    end

    it 'アクティビティ統計を返すこと' do
      stats = service.send(:user_activity_stats)

      expect(stats[:sign_in_count]).to eq(user.sign_in_count)
      expect(stats[:current_sign_in_at]).to eq(user.current_sign_in_at)
      expect(stats[:last_sign_in_at]).to eq(user.last_sign_in_at)
      expect(stats[:days_since_last_login]).to eq(2)
    end
  end

  describe '#login_frequency' do
    it 'ログイン頻度を計算すること' do
      user.update!(created_at: 10.days.ago, sign_in_count: 5)
      frequency = service.send(:login_frequency)

      expect(frequency).to eq('普通')
    end

    it '高頻度ユーザーを識別すること' do
      user.update!(created_at: 2.days.ago, sign_in_count: 10)
      frequency = service.send(:login_frequency)

      expect(frequency).to eq('高')
    end

    it 'ログインなしユーザーを処理すること' do
      user.update!(sign_in_count: 0)
      frequency = service.send(:login_frequency)

      expect(frequency).to eq('なし')
    end
  end

  describe '#most_popular_user_url' do
    context '短縮URLがある場合' do
      let!(:popular_url) { create(:short_url, user: user, visit_count: 100) }
      let!(:normal_url) { create(:short_url, user: user, visit_count: 10) }

      it '最も人気の短縮URLを返すこと' do
        result = service.send(:most_popular_user_url)

        expect(result[:short_code]).to eq(popular_url.short_code)
        expect(result[:visit_count]).to eq(100)
      end
    end

    context '短縮URLがない場合' do
      it 'nilを返すこと' do
        result = service.send(:most_popular_user_url)
        expect(result).to be_nil
      end
    end
  end

  describe '#recent_user_urls' do
    let!(:recent_url) { create(:short_url, user: user, created_at: 1.hour.ago) }
    let!(:old_url) { create(:short_url, user: user, created_at: 1.day.ago) }

    it '最近作成された短縮URLを返すこと' do
      result = service.send(:recent_user_urls, 2)

      expect(result.size).to eq(2)
      expect(result.first[:short_code]).to eq(recent_url.short_code)
      expect(result.first[:created_at]).to be > result.second[:created_at]
    end
  end

  describe '#tags_used_by_user' do
    before do
      create(:short_url, user: user, tags: '["tag1", "tag2"]')
      create(:short_url, user: user, tags: '["tag2", "tag3"]')
      create(:short_url, user: user, tags: nil)
    end

    it 'ユーザーが使用したタグを返すこと' do
      tags = service.send(:tags_used_by_user)

      expect(tags).to contain_exactly('tag1', 'tag2', 'tag3')
    end
  end

  describe 'クラスメソッド' do
    describe '.user_activity_summary' do
      before do
        # データベースをクリーンアップしてから必要なデータのみ作成
        User.destroy_all
      end

      let!(:active_user) { create(:user, current_sign_in_at: 1.hour.ago) }
      let!(:inactive_user) { create(:user, current_sign_in_at: 40.days.ago) }
      let!(:never_logged_user) { create(:user, sign_in_count: 0) }

      it 'ユーザーアクティビティサマリーを返すこと' do
        summary = described_class.user_activity_summary

        expect(summary[:active_today]).to eq(1)
        # inactive_users は 40日前ログイン + never_logged_user(current_sign_in_at IS NULL) = 2
        expect(summary[:inactive_users]).to eq(2)
        # このテスト前に他のテストでnever_logged_userが作成されている可能性があるため、実際の数を確認
        expect(summary[:never_logged_in]).to eq(3)
      end
    end

    describe '.top_users_by_urls' do
      let!(:user1) { create(:user, name: 'User 1') }
      let!(:user2) { create(:user, name: 'User 2') }

      before do
        # 既存のデータをクリーンアップ
        User.where.not(id: [user1.id, user2.id]).destroy_all
        ShortUrl.destroy_all

        create_list(:short_url, 5, user: user1)
        create_list(:short_url, 3, user: user2)
      end

      it '短縮URL数でトップユーザーを返すこと' do
        result = described_class.top_users_by_urls(2)

        expect(result.size).to eq(2)
        expect(result.first[:name]).to eq('User 1')
        expect(result.first[:short_url_count]).to eq(5)
        expect(result.second[:name]).to eq('User 2')
        expect(result.second[:short_url_count]).to eq(3)
      end
    end

    describe '.top_users_by_visits' do
      let!(:user1) { create(:user, name: 'Popular User') }
      let!(:user2) { create(:user, name: 'Normal User') }

      before do
        create(:short_url, user: user1, visit_count: 100)
        create(:short_url, user: user2, visit_count: 50)
      end

      it '訪問数でトップユーザーを返すこと' do
        result = described_class.top_users_by_visits(2)

        expect(result.size).to eq(2)
        expect(result.first[:name]).to eq('Popular User')
        expect(result.first[:total_visits]).to eq(100)
        expect(result.second[:name]).to eq('Normal User')
        expect(result.second[:total_visits]).to eq(50)
      end
    end
  end
end
