require 'rails_helper'

RSpec.describe 'Navigation Menu', type: :system do
  let(:user) { create(:user) }
  let(:oauth_user) { create(:user, :from_omniauth) }

  before do
    driven_by(:rack_test)
  end

  describe 'PC版ユーザードロップダウンメニュー' do
    before do
      sign_in user, scope: :user
    end

    it 'ユーザー情報が表示される' do
      visit dashboard_path

      expect(page).to have_content(user.display_name)
      expect(page).to have_css('[data-controller="user-menu"]')
    end

    it 'アカウント設定へのリンクが含まれる' do
      visit dashboard_path

      expect(page).to have_link('アカウント設定', href: account_path)
      expect(page).to have_css('svg[class*="w-5 h-5"]') # アイコンが表示されること
    end

    it 'ログアウトボタンが含まれる' do
      visit dashboard_path

      expect(page).to have_button('ログアウト')
      expect(page).to have_css('button[data-confirm="ログアウトしますか？"]')
    end

    context '管理者ユーザーの場合' do
      let(:admin_user) { create(:user, role: :admin) }

      before do
        sign_in admin_user, scope: :user
      end

      xit '管理者表示が含まれる' do
        visit dashboard_path

        expect(page).to have_content('管理者ユーザ')
      end
    end
  end

  describe 'モバイル版ハンバーガーメニュー' do
    before do
      sign_in user, scope: :user
    end

    it 'ナビゲーションリンクが表示される' do
      visit dashboard_path

      expect(page).to have_css('[data-mobile-menu-target="menu"]')
      expect(page).to have_link('URL作成', href: dashboard_path)
      expect(page).to have_link('マイページ', href: mypage_path)
      expect(page).to have_link('アカウント設定', href: account_path)
    end

    it 'モバイルユーザー情報が表示される' do
      visit dashboard_path

      expect(page).to have_content(user.display_name)
      expect(page).to have_css('.w-10.h-10.bg-blue-500') # アバター画像
    end

    it 'モバイルログアウトボタンが含まれる' do
      visit dashboard_path

      within('[data-mobile-menu-target="menu"]') do
        expect(page).to have_button('ログアウト')
        expect(page).to have_css('button[data-confirm="ログアウトしますか？"]')
      end
    end

    context '管理者ユーザーの場合' do
      let(:admin_user) { create(:user, role: :admin) }

      before do
        sign_in admin_user, scope: :user
      end

      xit 'モバイル版でも管理者表示が含まれる' do
        visit dashboard_path

        within('[data-mobile-menu-target="menu"]') do
          expect(page).to have_content('管理者ユーザ')
        end
      end
    end
  end

  describe 'ナビゲーション機能' do
    before do
      sign_in user, scope: :user
    end

    xit 'PC版ユーザードロップダウンからアカウント設定へのナビゲーションが動作する' do
      visit dashboard_path
      within('[data-controller="user-menu"]') do
        click_link 'アカウント設定'
      end

      expect(page).to have_current_path(account_path)
      expect(page).to have_content('アカウント設定')
    end

    xit 'PC版ナビゲーションからマイページへのナビゲーションが動作する' do
      visit dashboard_path
      within('.bg-gray-100.rounded-xl') do
        click_link 'マイページ'
      end

      expect(page).to have_current_path(mypage_path)
    end

    xit 'PC版ナビゲーションからダッシュボードへのナビゲーションが動作する' do
      visit mypage_path
      within('.bg-gray-100.rounded-xl') do
        click_link 'URL作成'
      end

      expect(page).to have_current_path(dashboard_path)
    end
  end

  describe 'レスポンシブデザイン' do
    before do
      sign_in user, scope: :user
    end

    it 'PC版メニューに適切なクラスが適用される' do
      visit dashboard_path

      expect(page).to have_css('.hidden.md\\:flex', visible: false) # PC版メニュー
      expect(page).to have_css('.md\\:hidden') # モバイル版ハンバーガーボタン
    end

    it 'アクセシビリティ属性が設定される' do
      visit dashboard_path

      expect(page).to have_css('button[data-action*="user-menu#toggle"]')
      expect(page).to have_css('[data-user-menu-target="dropdown"]')
    end
  end

  describe 'セキュリティ' do
    context 'ログインしていない場合' do
      it 'ユーザーメニューが表示されない' do
        visit root_path

        expect(page).not_to have_css('[data-controller="user-menu"]')
        expect(page).not_to have_content('ログアウト')
      end
    end

    context '異なるユーザーの情報' do
      let(:other_user) { create(:user, email: 'other@example.com', name: 'Other User') }

      before do
        sign_in user, scope: :user
      end

      it '他のユーザーの情報は表示されない' do
        visit dashboard_path

        expect(page).to have_content(user.display_name)
        expect(page).not_to have_content(other_user.display_name)
        expect(page).not_to have_content(other_user.email)
      end
    end
  end
end
