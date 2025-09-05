require 'rails_helper'

RSpec.describe 'ユーザー認証機能', type: :system do
  before do
    driven_by(:rack_test)
  end

  describe 'ユーザー登録' do
    it '新しいユーザーが登録できること' do
      visit new_user_registration_path

      expect(page).to have_content('新規登録')
      expect(page).to have_content('新しいアカウントを作成してください')

      fill_in 'user[email]', with: 'test@example.com'
      fill_in 'user[password]', with: 'password123'
      fill_in 'user[password_confirmation]', with: 'password123'

      click_button '新規登録'

      expect(page).to have_content('アカウント登録が完了しました')
      expect(page).to have_current_path(root_path)
    end

    it 'バリデーションエラーが表示されること' do
      visit new_user_registration_path

      click_button '新規登録'

      expect(page).to have_content('エラーが発生しました')
      expect(page).to have_content("Email can't be blank")
    end
  end

  describe 'ログイン' do
    let!(:user) { create(:user, email: 'test@example.com', password: 'password123') }

    it '正しい認証情報でログインできること' do
      visit new_user_session_path

      expect(page).to have_content('ログイン')
      expect(page).to have_content('アカウントにサインインしてください')

      fill_in 'user[email]', with: 'test@example.com'
      fill_in 'user[password]', with: 'password123'

      click_button 'ログイン'

      expect(page).to have_content('ログインしました')
      expect(page).to have_current_path(root_path)
    end

    it '間違った認証情報でログインできないこと' do
      visit new_user_session_path

      fill_in 'user[email]', with: 'test@example.com'
      fill_in 'user[password]', with: 'wrongpassword'

      click_button 'ログイン'

      expect(page).to have_content('メールアドレスまたはパスワードが違います')
      expect(page).to have_current_path(new_user_session_path)
    end
  end

  describe 'ログアウト' do
    let!(:user) { create(:user) }

    before do
      sign_in user
      visit root_path
    end

    it 'ログアウトできること' do
      expect(page).to have_button('ログアウト')

      click_button 'ログアウト'

      expect(page).to have_content('ログアウトしました')
      expect(page).to have_current_path(new_user_session_path)
    end
  end

  describe 'アクセス制御' do
    context 'ログインしていない場合' do
      it 'ルートページにアクセスするとログインページにリダイレクトされること' do
        visit root_path

        expect(page).to have_current_path(new_user_session_path)
        expect(page).to have_content('アカウント登録もしくはログインしてください')
      end

      it 'QRコードページにアクセスするとログインページにリダイレクトされること' do
        visit qr_code_path(short_code: 'test')

        expect(page).to have_current_path(new_user_session_path)
      end
    end

    context 'ログインしている場合' do
      let!(:user) { create(:user) }

      before do
        sign_in user
      end

      it 'ルートページにアクセスできること' do
        visit root_path

        expect(page).to have_content('URL短縮ツール')
        expect(page).to have_current_path(root_path)
      end

      it 'ナビゲーションバーが表示されること' do
        visit root_path

        expect(page).to have_content('Shlink-UI-Rails')
        expect(page).to have_content(user.display_name)
        expect(page).to have_content('Normal user')
        expect(page).to have_button('ログアウト')
      end
    end
  end

  describe 'ユーザーロール表示' do
    context '通常ユーザーの場合' do
      let!(:user) { create(:user) }

      before do
        sign_in user
        visit root_path
      end

      it 'Normal userと表示されること' do
        expect(page).to have_content('Normal user')
      end
    end

    context '管理者ユーザーの場合' do
      let!(:admin) { create(:user, :admin) }

      before do
        sign_in admin
        visit root_path
      end

      it 'Adminと表示されること' do
        expect(page).to have_content('Admin')
      end
    end
  end
end