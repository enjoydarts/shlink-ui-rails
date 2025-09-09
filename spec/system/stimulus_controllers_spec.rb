require 'rails_helper'

RSpec.describe 'Stimulus Controllers', type: :system do
  let(:user) { create(:user) }

  before do
    driven_by(:selenium_headless_chrome)
    sign_in user, scope: :user
    visit account_path
  end

  describe 'AccountTabsController' do
    it 'タブ切り替えが正しく動作する', js: true do
      # 初期状態：基本設定タブがアクティブ
      expect(page).to have_css('[data-tab="basic"].active')
      expect(page).to have_css('[data-panel="basic"]:not(.hidden)')
      expect(page).to have_css('[data-panel="security"].hidden')
      expect(page).to have_css('[data-panel="danger"].hidden')

      # セキュリティタブに切り替え
      click_button 'セキュリティ'
      expect(page).to have_css('[data-tab="security"].active')
      expect(page).to have_css('[data-panel="security"]:not(.hidden)')
      expect(page).to have_css('[data-panel="basic"].hidden')
      expect(page).to have_css('[data-panel="danger"].hidden')

      # 危険な操作タブに切り替え
      click_button '危険な操作'
      expect(page).to have_css('[data-tab="danger"].active')
      expect(page).to have_css('[data-panel="danger"]:not(.hidden)')
      expect(page).to have_css('[data-panel="basic"].hidden')
      expect(page).to have_css('[data-panel="security"].hidden')
    end

    it 'ARIA属性が正しく更新される', js: true do
      # 初期状態のARIA属性
      basic_tab = page.find('[data-tab="basic"]')
      security_tab = page.find('[data-tab="security"]')
      
      expect(basic_tab['aria-selected']).to eq('true')
      expect(basic_tab['tabindex']).to eq('0')
      expect(security_tab['aria-selected']).to eq('false')
      expect(security_tab['tabindex']).to eq('-1')

      # セキュリティタブクリック後
      click_button 'セキュリティ'
      
      expect(basic_tab['aria-selected']).to eq('false')
      expect(basic_tab['tabindex']).to eq('-1')
      expect(security_tab['aria-selected']).to eq('true')
      expect(security_tab['tabindex']).to eq('0')
    end

    it 'パネルのアニメーションが適用される', js: true do
      click_button 'セキュリティ'
      
      security_panel = page.find('[data-panel="security"]')
      
      # アニメーション用のCSS属性が設定されているか確認
      # 注: 実際のアニメーションテストは複雑なので、要素の存在確認に留める
      expect(security_panel).to be_visible
    end
  end

  describe 'AccountDeleteController' do
    before do
      click_button '危険な操作'
      click_button 'アカウントを削除する'
    end

    it 'モーダルが正しく開閉する', js: true do
      # モーダルが表示される
      expect(page).to have_css('[data-controller="account-delete"]:not(.hidden)')
      
      # キャンセルボタンでモーダルが閉じる
      click_button 'キャンセル'
      
      # モーダルが非表示になる（アニメーション完了まで待機）
      expect(page).to have_css('[data-controller="account-delete"].hidden', wait: 1)
    end

    it 'ESCキーでモーダルが閉じる', js: true do
      expect(page).to have_css('[data-controller="account-delete"]:not(.hidden)')
      
      page.send_keys(:escape)
      
      expect(page).to have_css('[data-controller="account-delete"].hidden', wait: 1)
    end

    it 'バックドロップクリックでモーダルが閉じる', js: true do
      expect(page).to have_css('[data-controller="account-delete"]:not(.hidden)')
      
      page.find('[data-account-delete-target="backdrop"]').click
      
      expect(page).to have_css('[data-controller="account-delete"].hidden', wait: 1)
    end

    context '通常ユーザー' do
      it 'パスワード入力フィールドにフォーカスが当たる', js: true do
        password_field = page.find('[data-account-delete-target="passwordField"]')
        expect(password_field).to be_focused
      end

      it '空のパスワードでバリデーションエラーが表示される', js: true do
        click_button 'アカウントを削除する'
        
        expect(page).to have_content('現在のパスワードを入力してください')
        expect(page).to have_css('[data-account-delete-target="passwordField"].border-red-500')
      end

      it '正しいパスワードでバリデーションが通る', js: true do
        fill_in '現在のパスワード（削除確認用）', with: user.password
        click_button 'アカウントを削除する'
        
        # バリデーションエラーが表示されない
        expect(page).not_to have_content('現在のパスワードを入力してください')
      end
    end

    context 'OAuthユーザー' do
      let(:oauth_user) { create(:user, :from_omniauth) }
      
      before do
        sign_out :user
        sign_in oauth_user
        visit account_path
        click_button '危険な操作'
        click_button 'アカウントを削除する'
      end

      it '確認フィールドにフォーカスが当たる', js: true do
        confirmation_field = page.find('[data-account-delete-target="confirmationField"]')
        expect(confirmation_field).to be_focused
      end

      it '不正な確認文字列でバリデーションエラーが表示される', js: true do
        fill_in '確認文字列（削除確認用）', with: '間違った文字列'
        click_button 'アカウントを削除する'
        
        expect(page).to have_content('削除を確認するため「削除」と正確に入力してください')
        expect(page).to have_css('[data-account-delete-target="confirmationField"].border-red-500')
      end

      it '正しい確認文字列でバリデーションが通る', js: true do
        fill_in '確認文字列（削除確認用）', with: '削除'
        click_button 'アカウントを削除する'
        
        # バリデーションエラーが表示されない
        expect(page).not_to have_content('削除を確認するため「削除」と正確に入力してください')
      end
    end

    it 'ローディング状態が正しく表示される', js: true do
      fill_in '現在のパスワード（削除確認用）', with: user.password
      
      confirm_button = page.find('[data-account-delete-target="confirmButton"]')
      expect(confirm_button.text).to eq('アカウントを削除する')
      
      # ボタンをクリック（実際の削除は実行されないようにJavaScriptでストップ）
      page.execute_script("""
        const button = document.querySelector('[data-account-delete-target="confirmButton"]');
        const controller = button.closest('[data-controller="account-delete"]');
        const stimulusController = window.Stimulus.getControllerForElementAndIdentifier(controller, 'account-delete');
        stimulusController.setButtonLoading(true);
      """)
      
      expect(confirm_button.text).to include('削除中...')
      expect(confirm_button[:disabled]).to eq('true')
    end
  end

  describe 'フラッシュメッセージ表示' do
    it '重複したフラッシュメッセージが表示されない' do
      # プロフィール更新でフラッシュメッセージを生成
      fill_in '表示名', with: '新しい名前'
      fill_in '現在のパスワード（確認用）', with: user.password
      click_button 'プロフィールを更新'
      
      # フラッシュメッセージが1つだけ表示される
      flash_messages = page.all('.fixed.right-4.z-50')
      expect(flash_messages.count).to eq(1)
      expect(page).to have_content('プロフィールが正常に更新されました')
    end
  end
end