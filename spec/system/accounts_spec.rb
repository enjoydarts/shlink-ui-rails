require 'rails_helper'

RSpec.describe 'Accounts', type: :system do
  let(:user) { create(:user) }
  let(:oauth_user) { create(:user, :from_omniauth) }

  before do
    driven_by(:selenium_headless_chrome)
  end

  describe 'アカウント設定画面' do
    context '通常ユーザーでログイン' do
      before do
        sign_in user, scope: :user
        visit account_path
      end

      it 'ページが正常に表示される' do
        expect(page).to have_content('アカウント設定')
        expect(page).to have_content('プロフィール情報とセキュリティ設定を管理')
        expect(page).to have_content(user.display_name)
        expect(page).to have_content(user.email)
      end

      it 'タブナビゲーションが機能する' do
        # 基本設定タブがデフォルトでアクティブ
        expect(page).to have_css('[data-tab="basic"].active')
        expect(page).to have_css('[data-panel="basic"]:not(.hidden)')

        # セキュリティタブをクリック
        click_button 'セキュリティ'
        expect(page).to have_css('[data-tab="security"].active')
        expect(page).to have_css('[data-panel="security"]:not(.hidden)')
        expect(page).to have_css('[data-panel="basic"].hidden')

        # 危険な操作タブをクリック
        click_button '危険な操作'
        expect(page).to have_css('[data-tab="danger"].active')
        expect(page).to have_css('[data-panel="danger"]:not(.hidden)')
        expect(page).to have_css('[data-panel="security"].hidden')
      end

      it 'プロフィール更新ができる' do
        # 基本設定タブで表示名を変更
        fill_in '表示名', with: '新しい名前'
        fill_in '現在のパスワード（確認用）', with: user.password
        click_button 'プロフィールを更新'

        expect(page).to have_content('プロフィールが正常に更新されました')
        expect(user.reload.name).to eq('新しい名前')
      end

      it 'パスワード変更ができる' do
        click_button 'セキュリティ'

        fill_in '新しいパスワード', with: 'new_password123'
        fill_in '新しいパスワード（確認）', with: 'new_password123'
        fill_in '現在のパスワード（確認用）', with: user.password
        click_button 'パスワードを変更'

        expect(page).to have_content('パスワードが正常に変更されました')
      end

      it 'アカウント削除モーダルが表示される' do
        click_button '危険な操作'
        click_button 'アカウントを削除する'

        expect(page).to have_css('[data-controller="account-delete"]')
        expect(page).to have_content('アカウントの削除')
        expect(page).to have_content(user.display_name)
        expect(page).to have_content(user.email)
      end

      it 'アカウント削除モーダルでキャンセルできる' do
        click_button '危険な操作'
        click_button 'アカウントを削除する'
        click_button 'キャンセル'

        expect(page).not_to have_css('[data-controller="account-delete"]:not(.hidden)')
      end

      it 'パスワードが正しい場合アカウント削除ができる' do
        click_button '危険な操作'
        click_button 'アカウントを削除する'

        fill_in '現在のパスワード（削除確認用）', with: user.password
        click_button 'アカウントを削除する'

        expect(page).to have_content('アカウントが正常に削除されました')
        expect(User.find_by(id: user.id)).to be_nil
      end
    end

    context 'OAuthユーザーでログイン' do
      before do
        sign_in oauth_user, scope: :user
        visit account_path
      end

      it 'OAuth用のUI要素が表示される' do
        expect(page).to have_content('Google認証ユーザー')

        # セキュリティタブを確認
        click_button 'セキュリティ'
        expect(page).to have_content('パスワード設定')
        expect(page).to have_content('Google認証に加えて、パスワードを設定することでより安全にアカウントを保護できます')
      end

      it 'OAuth用のアカウント削除確認が表示される' do
        click_button '危険な操作'
        click_button 'アカウントを削除する'

        expect(page).to have_field('確認文字列（削除確認用）')
        expect(page).to have_content('「削除」と入力してください')
      end

      it '正しい確認文字列でアカウント削除ができる' do
        click_button '危険な操作'
        click_button 'アカウントを削除する'

        fill_in '確認文字列（削除確認用）', with: '削除'
        click_button 'アカウントを削除する'

        expect(page).to have_content('アカウントが正常に削除されました')
        expect(User.find_by(id: oauth_user.id)).to be_nil
      end
    end
  end

  describe 'キーボードナビゲーション' do
    before do
      sign_in user
      visit account_path
    end

    it '矢印キーでタブを移動できる', js: true do
      # 基本設定タブにフォーカス
      page.find('[data-tab="basic"]').click

      # 右矢印でセキュリティタブに移動
      page.find('[data-tab="basic"]').send_keys(:arrow_right)
      expect(page).to have_css('[data-tab="security"].active')

      # 右矢印で危険な操作タブに移動
      page.find('[data-tab="security"]').send_keys(:arrow_right)
      expect(page).to have_css('[data-tab="danger"].active')

      # 左矢印でセキュリティタブに戻る
      page.find('[data-tab="danger"]').send_keys(:arrow_left)
      expect(page).to have_css('[data-tab="security"].active')
    end

    it 'Homeキーで最初のタブに移動できる', js: true do
      click_button '危険な操作'
      page.find('[data-tab="danger"]').send_keys(:home)
      expect(page).to have_css('[data-tab="basic"].active')
    end

    it 'Endキーで最後のタブに移動できる', js: true do
      page.find('[data-tab="basic"]').send_keys(:end)
      expect(page).to have_css('[data-tab="danger"].active')
    end
  end

  describe 'レスポンシブデザイン' do
    before do
      sign_in user
    end

    it 'モバイル表示で省略形のタブラベルが表示される' do
      page.driver.browser.manage.window.resize_to(375, 667) # iPhone SE size
      visit account_path

      expect(page).to have_content('基本')
      expect(page).to have_content('安全')
      expect(page).to have_content('危険')
    end

    it 'デスクトップ表示で完全なタブラベルが表示される' do
      page.driver.browser.manage.window.resize_to(1024, 768)
      visit account_path

      expect(page).to have_content('基本設定')
      expect(page).to have_content('セキュリティ')
      expect(page).to have_content('危険な操作')
    end
  end

  describe 'バリデーション' do
    before do
      sign_in user
      visit account_path
    end

    it 'プロフィール更新で不正なパスワードの場合エラーが表示される' do
      fill_in '表示名', with: '新しい名前'
      fill_in '現在のパスワード（確認用）', with: 'wrong_password'
      click_button 'プロフィールを更新'

      expect(page).to have_content('現在のパスワードが正しくありません')
    end

    it 'パスワード変更で確認パスワードが一致しない場合エラーが表示される' do
      click_button 'セキュリティ'

      fill_in '新しいパスワード', with: 'new_password123'
      fill_in '新しいパスワード（確認）', with: 'different_password'
      fill_in '現在のパスワード（確認用）', with: user.password
      click_button 'パスワードを変更'

      expect(page).to have_content('パスワードが一致しません')
    end
  end
end
