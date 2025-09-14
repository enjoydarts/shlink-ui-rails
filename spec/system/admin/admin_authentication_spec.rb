require 'rails_helper'

RSpec.describe '管理者認証', type: :system do
  let(:admin) { create(:user, email: 'admin@example.com', password: 'Password123!', password_confirmation: 'Password123!', role: 'admin') }
  let(:normal_user) { create(:user, email: 'user@example.com', password: 'Password123!', password_confirmation: 'Password123!', role: 'normal_user') }

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

  describe '管理者ログイン' do
    xit '管理者が正常にログインできること' do
      visit new_user_session_path

      expect(page).to have_content('ログイン')

      fill_in 'user_email', with: admin.email
      fill_in 'user_password', with: 'Password123!'
      click_button 'ログイン'

      visit admin_dashboard_path
      expect(page).to have_current_path(admin_dashboard_path)
      expect(page).to have_content('ダッシュボード')
    end

    xit '一般ユーザーはログインを拒否されること' do
      sign_in normal_user, scope: :user
      visit admin_dashboard_path

      expect(page).to have_current_path(dashboard_path)
      expect(page).to have_content('管理者権限が必要です')
      expect(page).not_to have_content('管理者パネル')
    end

    xit '無効な認証情報でログインを拒否されること' do
      visit new_user_session_path

      fill_in 'user_email', with: admin.email
      fill_in 'user_password', with: 'wrong_password'
      click_button 'ログイン'

      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_content('メールアドレスまたはパスワードが正しくありません')
    end

    it '既にログイン済みの管理者は管理者ダッシュボードにアクセスできること' do
      sign_in admin, scope: :user
      visit admin_dashboard_path

      expect(page).to have_current_path(admin_dashboard_path)
      expect(page).to have_content('ダッシュボード')
    end
  end

  describe 'アクセス制御' do
    context '未ログイン' do
      xit '管理者ページへのアクセスをブロックすること' do
        visit admin_dashboard_path
        expect(page).to have_current_path(new_user_session_path)

        visit admin_users_path
        expect(page).to have_current_path(new_user_session_path)

        visit admin_settings_path
        expect(page).to have_current_path(new_user_session_path)
      end
    end

    context '一般ユーザーでログイン' do
      before do
        sign_in normal_user, scope: :user
      end

      xit '管理者ページへのアクセスをブロックすること' do
        visit admin_dashboard_path
        expect(page).to have_current_path(dashboard_path)
        expect(page).to have_content('管理者権限が必要です')

        visit admin_users_path
        expect(page).to have_current_path(dashboard_path)

        visit admin_settings_path
        expect(page).to have_current_path(dashboard_path)
      end
    end

    context '管理者でログイン' do
      before do
        sign_in admin, scope: :user
      end

      xit '管理者ページにアクセスできること' do
        visit admin_dashboard_path
        expect(page).to have_content('ダッシュボード')

        visit admin_users_path
        expect(page).to have_content('ユーザー管理')

        visit admin_settings_path
        expect(page).to have_content('システム設定')
      end
    end
  end

  describe 'ナビゲーション' do
    before do
      sign_in admin, scope: :user
      visit admin_dashboard_path
    end

    xit 'サイドバーナビゲーションが正常に動作すること' do
      expect(page).to have_link('ダッシュボード', href: admin_dashboard_path)
      expect(page).to have_link('ユーザー管理', href: admin_users_path)
      expect(page).to have_link('システム設定', href: admin_settings_path)

      click_link 'ユーザー管理'
      expect(page).to have_current_path(admin_users_path)
      expect(page).to have_content('ユーザー管理')

      click_link 'システム設定'
      expect(page).to have_current_path(admin_settings_path)
      expect(page).to have_content('システム設定')

      click_link 'ダッシュボード'
      expect(page).to have_current_path(admin_dashboard_path)
    end

    xit 'ヘッダーリンクが正常に動作すること' do
      expect(page).to have_link('管理者パネル', href: admin_dashboard_path)
      expect(page).to have_link('サイトに戻る', href: root_path)
      expect(page).to have_link('ログアウト')

      click_link 'サイトに戻る'
      expect(page).to have_current_path(dashboard_path)
    end
  end

  describe 'ログアウト' do
    before do
      sign_in admin, scope: :user
      visit admin_dashboard_path
    end

    it '管理者が正常にログアウトできること' do
      click_link 'ログアウト'

      expect(page).to have_current_path(root_path)
      expect(page).to have_content('ログアウトしました')

      # ログアウト後は管理者ページにアクセスできないことを確認
      visit admin_dashboard_path
      expect(page).to have_current_path(new_user_session_path)
    end
  end
end
