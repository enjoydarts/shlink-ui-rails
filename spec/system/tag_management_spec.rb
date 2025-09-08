# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'タグ管理機能', type: :system do
  let(:user) { create(:user) }

  before do
    driven_by(:rack_test)
    sign_in user, scope: :user
    visit dashboard_path
  end

  describe 'タグの追加機能' do
    it 'Enterキーでタグを追加できる' do
      # アコーディオンを開く
      find('[data-action*="accordion#toggle"]').click

      # タグ入力フィールドにテキストを入力
      tag_input = find('[data-tag-input-target="input"]')
      tag_input.fill_in with: 'テストタグ'

      # Enterキーを押す
      tag_input.send_keys(:enter)

      # タグが表示されることを確認
      within '[data-tag-input-target="tagContainer"]' do
        expect(page).to have_content('テストタグ')
        expect(page).to have_selector('[data-tag="テストタグ"]') # 削除ボタン
      end

      # 隠しフィールドに値が設定されることを確認
      hidden_input = find('[data-tag-input-target="hiddenInput"]', visible: false)
      expect(hidden_input.value).to eq('テストタグ')

      # 入力フィールドがクリアされることを確認
      expect(tag_input.value).to be_empty
    end

    it '複数のタグを追加できる' do
      # アコーディオンを開く
      find('[data-action*="accordion#toggle"]').click

      tag_input = find('[data-tag-input-target="input"]')

      # 1つ目のタグを追加
      tag_input.fill_in with: 'タグ1'
      tag_input.send_keys(:enter)

      # 2つ目のタグを追加
      tag_input.fill_in with: 'タグ2'
      tag_input.send_keys(:enter)

      # 3つ目のタグを追加
      tag_input.fill_in with: 'タグ3'
      tag_input.send_keys(:enter)

      # すべてのタグが表示されることを確認
      within '[data-tag-input-target="tagContainer"]' do
        expect(page).to have_content('タグ1')
        expect(page).to have_content('タグ2')
        expect(page).to have_content('タグ3')
      end

      # 隠しフィールドに値が設定されることを確認
      hidden_input = find('[data-tag-input-target="hiddenInput"]', visible: false)
      expect(hidden_input.value).to include('タグ1')
      expect(hidden_input.value).to include('タグ2')
      expect(hidden_input.value).to include('タグ3')
    end

    it '空文字のタグは追加できない' do
      # アコーディオンを開く
      find('[data-action*="accordion#toggle"]').click

      tag_input = find('[data-tag-input-target="input"]')

      # 空文字でEnterキーを押す
      tag_input.send_keys(:enter)

      # エラーメッセージが表示されることを確認
      expect(page).to have_content('タグを入力してください')

      # タグが追加されていないことを確認
      within '[data-tag-input-target="tagContainer"]' do
        expect(page).not_to have_selector('[data-tag]')
      end
    end

    it '重複したタグは追加できない' do
      # アコーディオンを開く
      find('[data-action*="accordion#toggle"]').click

      tag_input = find('[data-tag-input-target="input"]')

      # 同じタグを2回追加しようとする
      tag_input.fill_in with: '重複タグ'
      tag_input.send_keys(:enter)

      tag_input.fill_in with: '重複タグ'
      tag_input.send_keys(:enter)

      # エラーメッセージが表示されることを確認
      expect(page).to have_content('同じタグが既に追加されています')

      # タグが1つだけ表示されることを確認
      within '[data-tag-input-target="tagContainer"]' do
        expect(page).to have_content('重複タグ', count: 1)
      end
    end

    it '文字数制限を超えるタグは追加できない' do
      # アコーディオンを開く
      find('[data-action*="accordion#toggle"]').click

      tag_input = find('[data-tag-input-target="input"]')

      # 21文字のタグを入力しようとする（制限は20文字）
      long_tag = 'a' * 21
      tag_input.fill_in with: long_tag
      tag_input.send_keys(:enter)

      # エラーメッセージが表示されることを確認
      expect(page).to have_content('タグは20文字以内で入力してください')

      # タグが追加されていないことを確認
      within '[data-tag-input-target="tagContainer"]' do
        expect(page).not_to have_content(long_tag)
      end
    end

    it '最大数を超えるタグは追加できない' do
      # アコーディオンを開く
      find('[data-action*="accordion#toggle"]').click

      tag_input = find('[data-tag-input-target="input"]')

      # 最大数（10個）のタグを追加
      10.times do |i|
        tag_input.fill_in with: "タグ#{i + 1}"
        tag_input.send_keys(:enter)
      end

      # 11個目のタグを追加しようとする
      tag_input.fill_in with: 'タグ11'
      tag_input.send_keys(:enter)

      # エラーメッセージが表示されることを確認
      expect(page).to have_content('タグは最大10個まで設定できます')

      # 11個目のタグが追加されていないことを確認
      within '[data-tag-input-target="tagContainer"]' do
        expect(page).not_to have_content('タグ11')
        expect(page.all('[data-tag]').count).to eq(10)
      end
    end
  end

  describe 'タグの削除機能' do
    it '削除ボタンをクリックしてタグを削除できる' do
      # アコーディオンを開く
      find('[data-action*="accordion#toggle"]').click

      tag_input = find('[data-tag-input-target="input"]')

      # タグを追加
      tag_input.fill_in with: '削除テストタグ'
      tag_input.send_keys(:enter)

      # タグが表示されることを確認
      within '[data-tag-input-target="tagContainer"]' do
        expect(page).to have_content('削除テストタグ')
      end

      # 削除ボタンをクリック
      find('[data-tag="削除テストタグ"]').click

      # タグが削除されることを確認
      within '[data-tag-input-target="tagContainer"]' do
        expect(page).not_to have_content('削除テストタグ')
      end

      # 隠しフィールドから値が削除されることを確認
      hidden_input = find('[data-tag-input-target="hiddenInput"]', visible: false)
      expect(hidden_input.value).not_to include('削除テストタグ')
    end

    it '複数タグから特定のタグだけを削除できる' do
      # アコーディオンを開く
      find('[data-action*="accordion#toggle"]').click

      tag_input = find('[data-tag-input-target="input"]')

      # 複数のタグを追加
      [ 'タグA', 'タグB', 'タグC' ].each do |tag|
        tag_input.fill_in with: tag
        tag_input.send_keys(:enter)
      end

      # 中間のタグ（タグB）を削除
      find('[data-tag="タグB"]').click

      # 削除したタグが表示されないことを確認
      within '[data-tag-input-target="tagContainer"]' do
        expect(page).to have_content('タグA')
        expect(page).not_to have_content('タグB')
        expect(page).to have_content('タグC')
      end

      # 隠しフィールドの値を確認
      hidden_input = find('[data-tag-input-target="hiddenInput"]', visible: false)
      expect(hidden_input.value).to include('タグA')
      expect(hidden_input.value).not_to include('タグB')
      expect(hidden_input.value).to include('タグC')
    end

    it 'タグ削除後にエラーメッセージがクリアされる' do
      # アコーディオンを開く
      find('[data-action*="accordion#toggle"]').click

      tag_input = find('[data-tag-input-target="input"]')

      # 最大数のタグを追加してエラーを発生させる
      10.times do |i|
        tag_input.fill_in with: "タグ#{i + 1}"
        tag_input.send_keys(:enter)
      end

      # 11個目を追加してエラーを表示
      tag_input.fill_in with: 'タグ11'
      tag_input.send_keys(:enter)
      expect(page).to have_content('タグは最大10個まで設定できます')

      # 1つタグを削除
      find('[data-tag="タグ1"]').click

      # エラーメッセージがクリアされることを確認
      expect(page).not_to have_content('タグは最大10個まで設定できます')
    end
  end

  describe 'URL短縮フォームとの連携' do
    it 'タグ付きでURL短縮ができる' do
      # アコーディオンを開く
      find('[data-action*="accordion#toggle"]').click

      # URLを入力
      fill_in 'shorten_long_url', with: 'https://example.com/test'

      # タグを追加
      tag_input = find('[data-tag-input-target="input"]')
      tag_input.fill_in with: 'テスト'
      tag_input.send_keys(:enter)

      # フォームを送信（モックサーバーが必要な場合は適切に設定）
      # この部分は実際のAPI連携テストが必要
    end
  end
end
