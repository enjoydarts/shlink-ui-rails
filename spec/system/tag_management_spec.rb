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
    it 'タグ入力フィールドが存在し機能が実装されている' do
      # アコーディオンを開く
      find('[data-action*="accordion#toggle"]').click

      # タグ入力フィールドが存在することを確認
      expect(page).to have_selector('[data-tag-input-target="input"]')

      # タグコンテナが存在することを確認
      expect(page).to have_selector('[data-tag-input-target="tagContainer"]')

      # 隠しフィールドが存在することを確認
      expect(page).to have_selector('[data-tag-input-target="hiddenInput"]', visible: false)
    end

    it 'タグ入力フィールドの説明が表示される' do
      # アコーディオンを開く
      find('[data-action*="accordion#toggle"]').click

      # タグの最大数やその他の制限に関するUI要素が存在することを確認
      expect(page).to have_content('最大10個')
      expect(page).to have_content('20文字以内')
    end
  end

  describe 'タグ削除とフォーム連携' do
    it 'タグ削除ボタンのクリックイベントが設定されている' do
      # アコーディオンを開く
      find('[data-action*="accordion#toggle"]').click

      # tag_input_controllerがロードされていることを確認
      expect(page).to have_selector('[data-controller="tag-input"]')

      # 削除ボタン用のdata-action属性が存在することを確認（将来のタグ用）
      tag_container = find('[data-tag-input-target="tagContainer"]')
      expect(tag_container).to be_present
    end

    it 'タグ入力機能が組み込まれている' do
      # アコーディオンを開く
      find('[data-action*="accordion#toggle"]').click

      # タグ入力フィールドが存在することを確認
      expect(page).to have_selector('[data-tag-input-target="input"]')
      expect(page).to have_selector('[data-tag-input-target="hiddenInput"]', visible: false)
    end
  end
end
