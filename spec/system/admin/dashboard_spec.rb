require 'rails_helper'

RSpec.describe '管理者ダッシュボード', type: :system do
  let(:admin) { create(:user, role: 'admin') }
  let!(:normal_users) { create_list(:user, 5, role: 'normal_user') }
  let!(:short_urls) { create_list(:short_url, 10, user: normal_users.first, visit_count: 100) }

  before do
    sign_in admin
    visit admin_dashboard_path
  end

  describe 'ダッシュボード表示' do
    it 'ダッシュボードが正常に表示されること' do
      expect(page).to have_content('ダッシュボード')
      expect(page).to have_content('システム全体の状況を確認できます')
    end

    it 'システム統計カードが表示されること' do
      expect(page).to have_content('総ユーザー数')
      expect(page).to have_content('短縮URL数')
      expect(page).to have_content('総アクセス数')
      expect(page).to have_content('システム稼働')

      # 実際の数値が表示されることを確認
      expect(page).to have_content('6') # 管理者1 + 一般ユーザー5
      expect(page).to have_content('10') # 短縮URL数
      expect(page).to have_content('1000') # 総アクセス数（100 × 10）
    end

    it 'システム健康状態が表示されること' do
      expect(page).to have_content('システム健康状態')
      expect(page).to have_content('データベース')
      expect(page).to have_content('Redis')
      expect(page).to have_content('ストレージ')
    end

    it 'サーバーリソース情報が表示されること' do
      expect(page).to have_content('サーバーリソース')
      expect(page).to have_content('メモリ使用率')
      expect(page).to have_content('ディスク使用率')
      expect(page).to have_content('CPU負荷')
    end

    it '人気の短縮URLセクションが表示されること' do
      expect(page).to have_content('人気の短縮URL')
    end

    it '最近の短縮URLセクションが表示されること' do
      expect(page).to have_content('最近の短縮URL')
    end

    it 'バックグラウンドジョブ情報が表示されること' do
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
      visit admin_dashboard_path

      expect(page).to have_content('7') # 更新されたユーザー数
    end

    it '新しい短縮URL作成後に統計が更新されること' do
      create(:short_url, user: normal_users.first, visit_count: 50)
      visit admin_dashboard_path

      expect(page).to have_content('11') # 短縮URL数
      expect(page).to have_content('1050') # 総アクセス数
    end
  end

  describe 'エラーハンドリング' do
    context 'データベース接続エラー' do
      before do
        allow_any_instance_of(Admin::DashboardController).to receive(:database_health).and_return(false)
        visit admin_dashboard_path
      end

      it 'データベースエラーが表示されること' do
        expect(page).to have_content('❌ 異常')
      end
    end
  end

  describe 'レスポンシブデザイン' do
    it 'モバイル表示でも正常に表示されること' do
      page.driver.browser.manage.window.resize_to(375, 812) # iPhone X size
      visit admin_dashboard_path

      expect(page).to have_content('ダッシュボード')
      expect(page).to have_content('総ユーザー数')
    end
  end
end
