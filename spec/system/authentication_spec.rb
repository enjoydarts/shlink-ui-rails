require 'rails_helper'

RSpec.describe 'ユーザー認証機能', type: :system do
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
  end

  describe 'ユーザー登録' do
    it '新しいユーザーが登録できること' do
      # CAPTCHA検証をスタブ化
      allow(CaptchaVerificationService).to receive(:verify).and_return(
        double(success?: true, error_codes: [])
      )

      visit new_user_registration_path

      expect(page).to have_content('新規登録')
      expect(page).to have_content('新しいアカウントを作成してください')

      fill_in 'user[email]', with: 'newuser@example.com'
      fill_in 'user[password]', with: 'Password123!'
      fill_in 'user[password_confirmation]', with: 'Password123!'

      click_button '新規登録'

      expect(page).to have_content('確認リンクを記載したメールを送信しました')
      expect(page).to have_current_path(root_path)
    end

    it 'バリデーションエラーが表示されること' do
      visit new_user_registration_path

      click_button '新規登録'

      expect(page).to have_content('入力エラー')
      expect(page).to have_content('メールアドレス を入力してください')
    end
  end

  describe 'ログイン' do
    let!(:user) { create(:user, password: 'Password123!', password_confirmation: 'Password123!') }

    before do
      # CAPTCHA検証をスタブ化
      allow(CaptchaVerificationService).to receive(:verify).and_return(
        double(success?: true, error_codes: [])
      )
    end

    xit '正しい認証情報でログインできること' do
      visit new_user_session_path

      expect(page).to have_content('ログイン')
      expect(page).to have_content('アカウントにサインインしてください')

      fill_in 'user[email]', with: user.email
      fill_in 'user[password]', with: 'Password123!'

      click_button 'ログイン'

      expect(page).to have_content('ログインしました')
      expect(page).to have_current_path(dashboard_path)
    end

    xit '間違った認証情報でログインできないこと' do
      visit new_user_session_path

      fill_in 'user[email]', with: user.email
      fill_in 'user[password]', with: 'wrongpassword'

      click_button 'ログイン'

      expect(page).to have_content('メールアドレスまたはパスワードが正しくありません')
      expect(page).to have_current_path(new_user_session_path)
    end
  end

  describe 'ログアウト' do
    let!(:user) { create(:user) }

    before do
      # システムテストでは実際にログインフォームを使用
      visit new_user_session_path
      fill_in 'user[email]', with: user.email
      fill_in 'user[password]', with: user.password
      click_button 'ログイン'

      visit dashboard_path
    end

    xit 'ログアウトできること' do
      # ページ上の任意のログアウトボタンを探す（デスクトップまたはモバイル）
      expect(page).to have_button('ログアウト')

      # 最初に見つかったログアウトボタンをクリック
      first('button', text: 'ログアウト').click

      expect(page).to have_content('ログアウトしました')
      expect(page).to have_current_path(root_path)
    end
  end

  describe 'アクセス制御' do
    context 'ログインしていない場合' do
      it 'ルートページにアクセスするとホームページが表示されること' do
        visit root_path

        expect(page).to have_current_path(root_path)
        expect(page).to have_content('URL短縮サービス Shlink UI')
      end

      it 'QRコードページにアクセスするとログインページにリダイレクトされること' do
        visit qr_code_path(short_code: 'test')

        expect(page).to have_current_path(new_user_session_path)
      end
    end

    context 'ログインしている場合' do
      let!(:user) { create(:user) }

      before do
        sign_in user, scope: :user
      end

      it 'ダッシュボードにアクセスできること' do
        visit dashboard_path

        expect(page).to have_content('URL短縮ツール')
        expect(page).to have_current_path(dashboard_path)
      end

      it 'ナビゲーションバーが表示されること' do
        visit dashboard_path

        expect(page).to have_content('Shlink-UI-Rails')
        expect(page).to have_content(user.display_name)
        expect(page).to have_button('ログアウト')
      end
    end
  end

  describe 'ユーザーロール表示' do
    context '通常ユーザーの場合' do
      let!(:user) { create(:user) }

      before do
        sign_in user, scope: :user
        visit dashboard_path
      end

      it 'ロール表示がないこと' do
        expect(page).not_to have_content('Normal user')
        expect(page).not_to have_content('通常ユーザ')
      end
    end

    context '管理者ユーザーの場合' do
      let!(:admin) { create(:user, :admin) }

      before do
        sign_in admin, scope: :user
        visit dashboard_path
      end

      it '管理者ユーザと表示されること' do
        expect(page).to have_content('管理者ユーザ')
      end
    end
  end
end
