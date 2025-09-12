require 'rails_helper'

RSpec.describe '管理者認証', type: :system do
  let(:admin) { create(:user, email: 'admin@example.com', password: 'password', role: 'admin') }
  let(:normal_user) { create(:user, email: 'user@example.com', password: 'password', role: 'normal_user') }

  describe '管理者ログイン' do
    it '管理者が正常にログインできること' do
      visit admin_login_path

      expect(page).to have_content('管理者ログイン')
      expect(page).to have_content('管理者権限でのログインが必要です')

      fill_in 'メールアドレス', with: admin.email
      fill_in 'パスワード', with: 'password'
      click_button '管理者としてログイン'

      expect(page).to have_current_path(admin_dashboard_path)
      expect(page).to have_content('管理者としてログインしました')
      expect(page).to have_content('管理者パネル')
      expect(page).to have_content('ダッシュボード')
    end

    it '一般ユーザーはログインを拒否されること' do
      visit admin_login_path

      fill_in 'メールアドレス', with: normal_user.email
      fill_in 'パスワード', with: 'password'
      click_button '管理者としてログイン'

      expect(page).to have_current_path(admin_login_path)
      expect(page).to have_content('管理者権限が必要です')
      expect(page).not_to have_content('管理者パネル')
    end

    it '無効な認証情報でログインを拒否されること' do
      visit admin_login_path

      fill_in 'メールアドレス', with: admin.email
      fill_in 'パスワード', with: 'wrong_password'
      click_button '管理者としてログイン'

      expect(page).to have_current_path(admin_login_path)
      expect(page).to have_content('メールアドレスまたはパスワードが正しくありません')
    end

    it '既にログイン済みの管理者は管理者ダッシュボードにリダイレクトされること' do
      sign_in admin
      visit admin_login_path

      expect(page).to have_current_path(admin_dashboard_path)
    end
  end

  describe 'アクセス制御' do
    context '未ログイン' do
      it '管理者ページへのアクセスをブロックすること' do
        visit admin_dashboard_path
        expect(page).to have_current_path(admin_login_path)

        visit admin_users_path
        expect(page).to have_current_path(admin_login_path)

        visit admin_settings_path
        expect(page).to have_current_path(admin_login_path)
      end
    end

    context '一般ユーザーでログイン' do
      before do
        sign_in normal_user
      end

      it '管理者ページへのアクセスをブロックすること' do
        visit admin_dashboard_path
        expect(page).to have_current_path(admin_login_path)

        visit admin_users_path
        expect(page).to have_current_path(admin_login_path)

        visit admin_settings_path
        expect(page).to have_current_path(admin_login_path)
      end
    end

    context '管理者でログイン' do
      before do
        sign_in admin
      end

      it '管理者ページにアクセスできること' do
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
      sign_in admin
      visit admin_dashboard_path
    end

    it 'サイドバーナビゲーションが正常に動作すること' do
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

    it 'ヘッダーリンクが正常に動作すること' do
      expect(page).to have_link('管理者パネル', href: admin_dashboard_path)
      expect(page).to have_link('サイトに戻る', href: root_path)
      expect(page).to have_link('ログアウト')

      click_link 'サイトに戻る'
      expect(page).to have_current_path(root_path)
    end
  end

  describe 'ログアウト' do
    before do
      sign_in admin
      visit admin_dashboard_path
    end

    it '管理者が正常にログアウトできること', js: true do
      accept_confirm do
        click_link 'ログアウト'
      end

      expect(page).to have_current_path(admin_login_path)
      expect(page).to have_content('ログアウトしました')

      # ログアウト後は管理者ページにアクセスできないことを確認
      visit admin_dashboard_path
      expect(page).to have_current_path(admin_login_path)
    end
  end
end
