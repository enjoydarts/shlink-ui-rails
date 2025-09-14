require 'rails_helper'

RSpec.describe Admin::SystemStatsService, type: :service do
  let(:service) { described_class.new }

  describe '#call' do
    before do
      # データベースをクリーンアップしてから必要なデータのみ作成
      User.destroy_all
      ShortUrl.destroy_all
    end

    let!(:admin_user) { create(:user, role: 'admin') }
    let!(:normal_user) { create(:user, role: 'normal_user') }
    let!(:short_url) { create(:short_url, user: normal_user, visit_count: 10) }

    it 'システム統計情報を返すこと' do
      result = service.call

      expect(result).to have_key(:users)
      expect(result).to have_key(:short_urls)
      expect(result).to have_key(:system)
    end

    it 'ユーザー統計情報が正しいこと' do
      result = service.call
      user_stats = result[:users]

      expect(user_stats[:total]).to eq(2)
      expect(user_stats[:admin]).to eq(1)
      expect(user_stats[:normal]).to eq(1)
    end

    it '短縮URL統計情報が正しいこと' do
      result = service.call
      url_stats = result[:short_urls]

      expect(url_stats[:total]).to eq(1)
      expect(url_stats[:total_visits]).to eq(10)
    end

    it 'システム情報を含むこと' do
      result = service.call
      system_stats = result[:system]

      expect(system_stats).to have_key(:uptime)
      expect(system_stats).to have_key(:version)
      expect(system_stats).to have_key(:database)
      expect(system_stats).to have_key(:background_jobs)
    end
  end

  describe '#user_statistics' do
    before do
      # データベースをクリーンアップしてから必要なデータのみ作成
      User.destroy_all
    end

    let!(:users) { create_list(:user, 5, role: 'normal_user') }
    let!(:admin) { create(:user, role: 'admin') }

    it '正確なユーザー数を返すこと' do
      stats = service.send(:user_statistics)
      expect(stats[:total]).to eq(6)
      expect(stats[:admin]).to eq(1)
      expect(stats[:normal]).to eq(5)
    end
  end

  describe '#short_url_statistics' do
    before do
      # データベースをクリーンアップしてから必要なデータのみ作成
      User.destroy_all
      ShortUrl.destroy_all
    end

    let(:user) { create(:user) }
    let!(:short_urls) { create_list(:short_url, 3, user: user, visit_count: 5) }

    it '正確な短縮URL統計を返すこと' do
      stats = service.send(:short_url_statistics)
      expect(stats[:total]).to eq(3)
      expect(stats[:total_visits]).to eq(15)
    end

    it '人気の短縮URLを返すこと' do
      popular_url = create(:short_url, user: user, visit_count: 100)
      stats = service.send(:short_url_statistics)

      expect(stats[:most_popular]).to be_an(Array)
      expect(stats[:most_popular].first[:short_code]).to eq(popular_url.short_code)
    end
  end

  describe '#system_statistics' do
    it 'システム統計情報を返すこと' do
      stats = service.send(:system_statistics)

      expect(stats).to have_key(:uptime)
      expect(stats).to have_key(:version)
      expect(stats).to have_key(:database)
      expect(stats).to have_key(:background_jobs)
    end

    it 'Rails情報が含まれること' do
      stats = service.send(:system_statistics)
      version_info = stats[:version]

      expect(version_info[:rails]).to eq(Rails.version)
      expect(version_info[:ruby]).to eq(RUBY_VERSION)
      expect(version_info[:environment]).to eq(Rails.env)
    end
  end

  describe '#most_popular_short_urls' do
    let(:user) { create(:user) }

    before do
      create(:short_url, user: user, visit_count: 10, short_code: 'abc123')
      create(:short_url, user: user, visit_count: 20, short_code: 'def456')
      create(:short_url, user: user, visit_count: 5, short_code: 'ghi789')
    end

    it '訪問数順で短縮URLを返すこと' do
      result = service.send(:most_popular_short_urls, 2)

      expect(result.size).to eq(2)
      expect(result.first[:short_code]).to eq('def456')
      expect(result.first[:visit_count]).to eq(20)
      expect(result.second[:short_code]).to eq('abc123')
      expect(result.second[:visit_count]).to eq(10)
    end
  end

  describe '#recent_short_urls' do
    before do
      # データベースをクリーンアップしてから必要なデータのみ作成
      User.destroy_all
      ShortUrl.destroy_all
    end

    let(:user) { create(:user, name: 'Test User') }

    before do
      create(:short_url, user: user, created_at: 1.day.ago)
      create(:short_url, user: user, created_at: 2.days.ago)
    end

    it '作成日時順で短縮URLを返すこと' do
      result = service.send(:recent_short_urls, 2)

      expect(result.size).to eq(2)
      expect(result.first[:created_at]).to be > result.second[:created_at]
      expect(result.first[:user_name]).to eq('Test User')
    end
  end

  describe '#format_uptime' do
    it '秒数を適切にフォーマットすること' do
      expect(service.send(:format_uptime, 3661)).to eq('1時間 1分')
      expect(service.send(:format_uptime, 90061)).to eq('1日 1時間 1分')
      expect(service.send(:format_uptime, 120)).to eq('2分')
    end
  end

  describe '#truncate_url' do
    it 'URLを適切に切り詰めること' do
      long_url = 'https://example.com/' + 'a' * 100
      result = service.send(:truncate_url, long_url, 50)

      expect(result.length).to eq(50)
      expect(result).to end_with('...')
    end

    it '短いURLはそのまま返すこと' do
      short_url = 'https://example.com/'
      result = service.send(:truncate_url, short_url, 50)

      expect(result).to eq(short_url)
    end
  end
end
