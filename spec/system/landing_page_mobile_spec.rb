# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ランディングページのモバイル表示', type: :system do
  before do
    driven_by(:rack_test)
    visit root_path
  end

  context 'モバイル向け要素が存在することを確認' do
    it 'ハンバーガーメニューボタンが存在する' do
      within 'nav' do
        expect(page).to have_selector('[data-action*="mobile-menu#toggle"]')
        expect(page).to have_selector('svg') # ハンバーガーアイコン
      end
    end

    it 'デスクトップ用のナビゲーションリンクにhiddenクラスが設定されている' do
      within 'nav' do
        expect(page).to have_selector('.hidden.md\\:flex')
      end
    end

    it 'モバイルメニューが存在し、初期状態で非表示' do
      # モバイルメニューターゲットが存在することを確認
      expect(page).to have_selector('[data-mobile-menu-target="menu"]')

      # 初期状態でhiddenクラスが付いていることを確認
      menu = find('[data-mobile-menu-target="menu"]')
      expect(menu[:class]).to include('hidden')
    end

    it 'モバイルメニュー内に必要なリンクが存在する' do
      within '[data-mobile-menu-target="menu"]' do
        expect(page).to have_link('今すぐ始める', href: new_user_registration_path)
        expect(page).to have_link('ログインして続ける', href: new_user_session_path)
      end
    end

    it 'メイン部分にCTAボタンが表示される' do
      within '.flex-1' do # Hero Section
        expect(page).to have_link('今すぐ始める', href: new_user_registration_path)
        expect(page).to have_link('ログインして続ける', href: new_user_session_path)
      end
    end
  end

  context 'デスクトップ向け要素の確認' do
    it 'ハンバーガーメニューボタンの親要素にmd:hiddenクラスが設定されている' do
      within 'nav' do
        hamburger_container = find('[data-action*="mobile-menu#toggle"]').find(:xpath, '..')
        expect(hamburger_container[:class]).to include('md:hidden')
      end
    end

    it 'デスクトップ用のナビゲーションリンクが存在する' do
      within 'nav' do
        expect(page).to have_selector('.hidden.md\\:flex')
        expect(page).to have_link('ログイン', href: new_user_session_path)
        expect(page).to have_link('新規登録', href: new_user_registration_path)
      end
    end
  end
end
