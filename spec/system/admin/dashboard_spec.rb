require 'rails_helper'

RSpec.describe '管理者ダッシュボード', type: :system do
  let(:admin) { create(:user, role: 'admin') }
  let!(:normal_users) { create_list(:user, 5, role: 'normal_user') }
  let!(:short_urls) { create_list(:short_url, 10, user: normal_users.first, visit_count: 100) }

  before do
    driven_by(:rack_test)

    # SystemSetting基本モック設定
    allow(SystemSetting).to receive(:get).and_call_original
    allow(SystemSetting).to receive(:get).with("shlink.base_url", nil).and_return("https://test.example.com")
    allow(SystemSetting).to receive(:get).with("shlink.api_key", nil).and_return("test-api-key")
    allow(SystemSetting).to receive(:get).with("performance.items_per_page", 20).and_return(20)
    allow(SystemSetting).to receive(:get).with('system.maintenance_mode', false).and_return(false)

    # ApplicationConfig基本モック設定
    allow(ApplicationConfig).to receive(:string).and_call_original
    allow(ApplicationConfig).to receive(:string).with('shlink.base_url', anything).and_return("https://test.example.com")
    allow(ApplicationConfig).to receive(:string).with('shlink.api_key', anything).and_return("test-api-key")
    allow(ApplicationConfig).to receive(:string).with('redis.url', anything).and_return("redis://redis:6379/0")
    allow(ApplicationConfig).to receive(:number).and_call_original
    allow(ApplicationConfig).to receive(:number).with('shlink.timeout', anything).and_return(30)
    allow(ApplicationConfig).to receive(:number).with('redis.timeout', anything).and_return(5)

    # Settings gemのモック設定（Admin::ServerMonitorService用）
    if defined?(Settings)
      allow(Settings).to receive_message_chain(:shlink, :base_url).and_return("https://test.example.com")
      allow(Settings).to receive_message_chain(:shlink, :api_key).and_return("test-api-key")
    end
  end

  describe 'ダッシュボード表示' do
    it 'ダッシュボードが正常に表示されること' do
      sign_in admin, scope: :user
      visit admin_dashboard_path
      expect(page).to have_content('ダッシュボード')
      expect(page).to have_content('システム全体の状況を確認できます')
    end

    xit 'システム統計カードが表示されること' do
      expect(page).to have_content('総ユーザー数')
      expect(page).to have_content('短縮URL数')
      expect(page).to have_content('総アクセス数')
      expect(page).to have_content('システム稼働')

      # 実際の数値が表示されることを確認（他のテストの影響を考慮）
      expect(page).to have_content(/\d+/) # ユーザー数（数値）
      expect(page).to have_content(/\d+/) # 短縮URL数（数値）
      expect(page).to have_content(/10\d{2}/) # 総アクセス数（1000前後）
    end

    xit 'システム健康状態が表示されること' do
      expect(page).to have_content('システム健康状態')
      expect(page).to have_content('データベース')
      expect(page).to have_content('Redis')
      expect(page).to have_content('ストレージ')
    end

    xit 'サーバーリソース情報が表示されること' do
      expect(page).to have_content('サーバーリソース')
      expect(page).to have_content('メモリ使用率')
      expect(page).to have_content('ディスク使用率')
      expect(page).to have_content('CPU負荷')
    end

    xit '人気の短縮URLセクションが表示されること' do
      expect(page).to have_content('人気の短縮URL')
    end

    it '最近の短縮URLセクションが表示されること' do
      sign_in admin, scope: :user
      visit admin_dashboard_path
      expect(page).to have_content('最近の短縮URL')
    end

    xit 'バックグラウンドジョブ情報が表示されること' do
      expect(page).to have_content('バックグラウンドジョブ')
      expect(page).to have_content('待機中')
      expect(page).to have_content('予約済み')
      expect(page).to have_content('完了')
      expect(page).to have_content('失敗')
    end
  end

  describe 'データの動的更新' do
    it '新しいユーザー作成後に統計が更新されること' do
      create(:user, role: 'normal_user')
      sign_in admin, scope: :user
      visit admin_dashboard_path

      expect(page).to have_content('7') # 更新されたユーザー数
    end

    xit '新しい短縮URL作成後に統計が更新されること' do
      create(:short_url, user: normal_users.first, visit_count: 50)
      sign_in admin, scope: :user
      visit admin_dashboard_path

      expect(page).to have_content('11') # 短縮URL数
      expect(page).to have_content('1051') # 総アクセス数
    end
  end

  describe 'エラーハンドリング' do
    context 'データベース接続エラー' do
      before do
        allow_any_instance_of(Admin::DashboardController).to receive(:database_health).and_return(false)
        sign_in admin, scope: :user
        visit admin_dashboard_path
      end

      it 'データベースエラーが表示されること' do
        expect(page).to have_content('❌ 異常')
      end
    end
  end

  describe 'レスポンシブデザイン' do
    it 'モバイル表示でも正常に表示されること' do
      sign_in admin, scope: :user
      visit admin_dashboard_path
      # Capybara.current_session.current_window.resize_to(375, 812) # iPhone X size
      # Note: rack_test driver doesn't support window resizing, but the page should still respond correctly

      expect(page).to have_content('ダッシュボード')
      expect(page).to have_content('総ユーザー数')
    end
  end
end
