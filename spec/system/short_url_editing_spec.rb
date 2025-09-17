require 'rails_helper'

RSpec.describe 'Short URL editing', type: :system do
  before { driven_by(:rack_test) }
  let(:user) { create(:user) }
  let!(:short_url) do
    create(:short_url,
      user: user,
      short_code: 'test123',
      title: 'Original Title',
      long_url: 'https://original.example.com',
      tags: [ 'original-tag' ].to_json,
      max_visits: 50,
      short_url: 'https://s.test/test123'
    )
  end

  before do
    sign_in user, scope: :user
  end

  describe 'URL編集機能' do
    context 'マイページからの編集' do
      it '編集ページが正しく表示される' do
        # 編集ページにアクセス
        visit edit_short_url_path(short_url.short_code)

        # 編集ページが表示されることを確認
        expect(page).to have_content('短縮URL編集')
        expect(page).to have_field('edit_short_url_form_title', with: 'Original Title')
        expect(page).to have_field('edit_short_url_form_long_url', with: 'https://original.example.com')
        expect(page).to have_field('edit_short_url_form_tags', with: 'original-tag')
        expect(page).to have_field('edit_short_url_form_max_visits', with: '50')
        expect(page).to have_button('更新')
        expect(page).to have_link('キャンセル')
      end

      it 'フォームを正しく更新できる' do
        # Shlink API更新をモック
        stub_request(:patch, "#{ENV['SHLINK_BASE_URL']}/rest/v3/short-urls/test123")
          .to_return(
            status: 200,
            body: {
              shortUrl: "https://s.test/test123",
              shortCode: "test123",
              longUrl: "https://updated.example.com",
              title: "Updated Title",
              tags: [ "updated-tag1", "updated-tag2" ],
              meta: {
                maxVisits: 100,
                validUntil: nil
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # 編集ページにアクセス
        visit edit_short_url_path(short_url.short_code)

        # フォームを入力
        fill_in 'edit_short_url_form_title', with: 'Updated Title'
        fill_in 'edit_short_url_form_long_url', with: 'https://updated.example.com'
        fill_in 'edit_short_url_form_tags', with: 'updated-tag1, updated-tag2'
        fill_in 'edit_short_url_form_max_visits', with: '100'

        # 更新ボタンをクリック
        click_button '更新'

        # 成功時はマイページにリダイレクトされる
        expect(page).to have_content('マイページ')
      end

      it 'バリデーションエラーが表示される' do
        # 編集ページにアクセス
        visit edit_short_url_path(short_url.short_code)

        # 無効な値を入力
        fill_in 'edit_short_url_form_long_url', with: 'invalid-url'
        fill_in 'edit_short_url_form_max_visits', with: '-1'

        # 更新ボタンをクリック
        click_button '更新'

        # エラーメッセージが表示されることを確認
        expect(page).to have_content('入力内容を確認してください')
      end

      it 'Shlink APIエラー時にエラーメッセージが表示される' do
        # Shlink API更新エラーをモック
        stub_request(:patch, "#{ENV['SHLINK_BASE_URL']}/rest/v3/short-urls/test123")
          .to_return(
            status: 500,
            body: { error: 'Internal server error' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # 編集ページにアクセス
        visit edit_short_url_path(short_url.short_code)

        # フォームを入力
        fill_in 'edit_short_url_form_title', with: 'Updated Title'

        # 更新ボタンをクリック
        click_button '更新'

        # エラーメッセージが表示されることを確認
        expect(page).to have_content('更新に失敗しました')
      end
    end

    context 'セキュリティ' do
      it '他ユーザーのURLは編集できない' do
        other_user = create(:user)
        other_short_url = create(:short_url, user: other_user, short_code: 'other123')

        # 他のユーザーのURL編集ページにアクセス
        visit edit_short_url_path(other_short_url.short_code)

        # アクセス拒否されることを確認
        expect(page).to have_content('指定された短縮URLが見つかりません')
      end
    end

    context 'レスポンシブデザイン' do
      it '編集ページが正しく表示される' do
        # 編集ページにアクセス
        visit edit_short_url_path(short_url.short_code)

        # 編集ページが表示されることを確認
        expect(page).to have_content('短縮URL編集')
        expect(page).to have_field('edit_short_url_form_title')
        expect(page).to have_button('更新')
      end
    end
  end
end
