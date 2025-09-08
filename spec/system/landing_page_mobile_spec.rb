# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ランディングページのモバイル表示', type: :system do
  before do
    driven_by(:rack_test)
  end

  context 'モバイル画面サイズで表示する場合' do
    before do
      # モバイル画面サイズに設定（375x667 - iPhone SE）
      page.driver.browser.manage.window.resize_to(375, 667)
      visit root_path
    end

    it 'ハンバーガーメニューボタンが表示される' do
      within 'nav' do
        expect(page).to have_selector('[data-action*="mobile-menu#toggle"]', visible: true)
        expect(page).to have_selector('svg', visible: true) # ハンバーガーアイコン
      end
    end

    it 'デスクトップ用のナビゲーションリンクが非表示になる' do
      within 'nav' do
        expect(page).to have_selector('.hidden.md\\:flex', visible: false)
      end
    end

    it 'ハンバーガーメニューをクリックしてモバイルメニューが開く' do
      # 初期状態ではモバイルメニューが非表示
      expect(page).to have_selector('[data-mobile-menu-target="menu"]', visible: false)

      # ハンバーガーボタンをクリック
      find('[data-action*="mobile-menu#toggle"]').click

      # モバイルメニューが表示される
      expect(page).to have_selector('[data-mobile-menu-target="menu"]', visible: true)
    end

    it 'モバイルメニュー内に「今すぐ始める」ボタンが表示される' do
      # ハンバーガーボタンをクリックしてメニューを開く
      find('[data-action*="mobile-menu#toggle"]').click

      within '[data-mobile-menu-target="menu"]' do
        expect(page).to have_link('今すぐ始める', href: new_user_registration_path)
      end
    end

    it 'モバイルメニュー内に「ログインして続ける」ボタンが表示される' do
      # ハンバーガーボタンをクリックしてメニューを開く
      find('[data-action*="mobile-menu#toggle"]').click

      within '[data-mobile-menu-target="menu"]' do
        expect(page).to have_link('ログインして続ける', href: new_user_session_path)
      end
    end

    it 'メイン部分の「今すぐ始める」ボタンがモバイルでも表示される' do
      within '.flex-1' do # Hero Section
        expect(page).to have_link('今すぐ始める', href: new_user_registration_path)
      end
    end

    it 'メイン部分の「ログインして続ける」ボタンがモバイルでも表示される' do
      within '.flex-1' do # Hero Section
        expect(page).to have_link('ログインして続ける', href: new_user_session_path)
      end
    end

    it 'Escキーでモバイルメニューが閉じる' do
      # メニューを開く
      find('[data-action*="mobile-menu#toggle"]').click
      expect(page).to have_selector('[data-mobile-menu-target="menu"]', visible: true)

      # Escキーを押す
      page.driver.browser.action.send_keys(:escape).perform

      # メニューが閉じる（アニメーション時間を考慮）
      sleep 0.3
      expect(page).to have_selector('[data-mobile-menu-target="menu"]', visible: false)
    end

    it 'メニュー外部をクリックしてモバイルメニューが閉じる' do
      # メニューを開く
      find('[data-action*="mobile-menu#toggle"]').click
      expect(page).to have_selector('[data-mobile-menu-target="menu"]', visible: true)

      # メニュー外部（ヘッダー部分）をクリック
      find('h1', text: 'Shlink UI').click

      # メニューが閉じる（アニメーション時間を考慮）
      sleep 0.3
      expect(page).to have_selector('[data-mobile-menu-target="menu"]', visible: false)
    end
  end

  context 'デスクトップ画面サイズで表示する場合' do
    before do
      # デスクトップ画面サイズに設定
      page.driver.browser.manage.window.resize_to(1024, 768)
      visit root_path
    end

    it 'ハンバーガーメニューボタンが非表示になる' do
      within 'nav' do
        expect(page).to have_selector('.md\\:hidden', visible: false)
      end
    end

    it 'デスクトップ用のナビゲーションリンクが表示される' do
      within 'nav' do
        expect(page).to have_selector('.hidden.md\\:flex', visible: true)
        expect(page).to have_link('ログイン', href: new_user_session_path)
        expect(page).to have_link('新規登録', href: new_user_registration_path)
      end
    end
  end
end
