require 'rails_helper'

RSpec.describe 'Accounts', type: :system do
  let(:user) { create(:user) }
  let(:oauth_user) { create(:user, :from_omniauth) }

  describe 'アカウント設定画面' do
    context '通常ユーザーでログイン' do
      before do
        sign_in user, scope: :user
        visit account_path
      end

      it 'ページが正常に表示される' do
        expect(page).to have_content('アカウント設定')
        expect(page).to have_content('プロフィール情報とセキュリティ設定を管理')
        expect(page).to have_css('[data-controller="account-tabs"]')
      end

      it 'タブナビゲーション要素が存在する' do
        expect(page).to have_css('[role="tablist"]')
        expect(page).to have_css('[data-tab="basic"]')
        expect(page).to have_css('[data-tab="security"]')
        expect(page).to have_css('[data-tab="danger"]')
      end

      it 'アカウント削除要素が存在する' do
        expect(page).to have_css('[data-controller="account-delete"]')
        expect(page).to have_button('アカウントを削除する')
      end

    end

    context 'OAuthユーザーでログイン' do
      before do
        sign_in oauth_user, scope: :user
        visit account_path
      end

      it 'OAuth用のUI要素が表示される' do
        expect(page).to have_content('Google認証ユーザー')
        expect(page).to have_css('[data-account-delete-is-oauth-user-value="true"]')
      end

    end
  end

  describe 'レスポンシブデザイン' do
    before do
      sign_in user, scope: :user
      visit account_path
    end

    it 'レスポンシブ用のCSSクラスが設定されている' do
      # モバイル用の省略ラベル
      expect(page).to have_css('.sm\\:hidden', text: '基本')
      expect(page).to have_css('.sm\\:hidden', text: '安全')
      expect(page).to have_css('.sm\\:hidden', text: '危険')

      # デスクトップ用の完全ラベル
      expect(page).to have_css('.hidden.sm\\:inline', text: '基本設定')
      expect(page).to have_css('.hidden.sm\\:inline', text: 'セキュリティ')
      expect(page).to have_css('.hidden.sm\\:inline', text: '危険な操作')
    end
  end

end
