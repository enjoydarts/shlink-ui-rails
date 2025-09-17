require 'rails_helper'

RSpec.describe 'Short URL editing', type: :system do
  let(:user) { create(:user) }
  let!(:short_url) do
    create(:short_url,
      user: user,
      short_code: 'test123',
      title: 'Original Title',
      long_url: 'https://original.example.com',
      tags: [ 'original-tag' ].to_json,
      max_visits: 50
    )
  end

  before do
    sign_in user
    visit mypage_path
  end

  describe 'URL編集機能' do
    context 'マイページからの編集' do
      it '編集ボタンをクリックするとモーダルが表示される', js: true do
        # 編集ボタンがあることを確認
        within("#short-url-card-#{short_url.short_code}") do
          expect(page).to have_css('button[title="編集"]')
        end

        # モックを設定
        stub_request(:get, %r{/short_urls/test123/edit})
          .to_return(
            status: 200,
            body: turbo_stream_edit_response,
            headers: { 'Content-Type' => 'text/vnd.turbo-stream.html' }
          )

        # 編集ボタンをクリック
        within("#short-url-card-#{short_url.short_code}") do
          find('button[title="編集"]').click
        end

        # モーダルが表示されることを確認
        expect(page).to have_content('短縮URL編集')
        expect(page).to have_field('タイトル', with: 'Original Title')
        expect(page).to have_field('元のURL', with: 'https://original.example.com')
        expect(page).to have_field('タグ', with: 'original-tag')
        expect(page).to have_field('訪問制限', with: '50')
      end

      it 'フォームを正しく更新できる', js: true do
        # Shlink API更新をモック
        stub_request(:patch, %r{/rest/v3/short-urls/test123})
          .to_return(
            status: 200,
            body: shlink_update_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # 編集モーダルを開く
        open_edit_modal

        # フォームを入力
        fill_in 'タイトル', with: 'Updated Title'
        fill_in '元のURL', with: 'https://updated.example.com'
        fill_in 'タグ', with: 'updated-tag1, updated-tag2'
        fill_in '訪問制限', with: '100'

        # 更新ボタンをクリック
        click_button '更新'

        # 成功メッセージが表示されることを確認
        expect(page).to have_content('短縮URLを更新しました')

        # モーダルが閉じることを確認
        expect(page).not_to have_content('短縮URL編集')

        # URLカードが更新されることを確認
        within("#short-url-card-#{short_url.short_code}") do
          expect(page).to have_content('Updated Title')
        end
      end

      it 'バリデーションエラーが表示される', js: true do
        open_edit_modal

        # 無効なURLを入力
        fill_in '元のURL', with: 'invalid-url'

        # 更新ボタンをクリック
        click_button '更新'

        # エラーメッセージが表示されることを確認
        expect(page).to have_content('入力内容を確認してください')
        expect(page).to have_content('不正な値です')

        # モーダルが開いたままであることを確認
        expect(page).to have_content('短縮URL編集')
      end

      it 'ESCキーでモーダルを閉じることができる', js: true do
        open_edit_modal

        # ESCキーを押す
        page.driver.browser.action.send_keys(:escape).perform

        # モーダルが閉じることを確認
        expect(page).not_to have_content('短縮URL編集')
      end

      it 'キャンセルボタンでモーダルを閉じることができる', js: true do
        open_edit_modal

        # キャンセルボタンをクリック
        click_button 'キャンセル'

        # モーダルが閉じることを確認
        expect(page).not_to have_content('短縮URL編集')
      end

      it 'Shlink APIエラー時にエラーメッセージが表示される', js: true do
        # Shlink APIエラーをモック
        stub_request(:patch, %r{/rest/v3/short-urls/test123})
          .to_return(
            status: 500,
            body: { error: 'Internal Server Error' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        open_edit_modal

        fill_in 'タイトル', with: 'Updated Title'
        click_button '更新'

        # エラーメッセージが表示されることを確認
        expect(page).to have_content('更新に失敗しました')
      end
    end

    context 'セキュリティ' do
      let(:other_user) { create(:user) }
      let!(:other_short_url) do
        create(:short_url,
          user: other_user,
          short_code: 'other123',
          title: 'Other User URL'
        )
      end

      it '他ユーザーのURLは編集できない' do
        # 直接編集URLにアクセス
        visit "/short_urls/other123/edit"

        # アクセス拒否されることを確認（404または403）
        expect(page).to have_http_status(:not_found)
      end
    end

    context 'レスポンシブデザイン' do
      it 'モバイルサイズでも編集フォームが正しく表示される', js: true do
        # モバイルサイズに変更
        page.driver.browser.manage.window.resize_to(375, 667)

        open_edit_modal

        # フォームが表示されることを確認
        expect(page).to have_field('タイトル')
        expect(page).to have_field('元のURL')
        expect(page).to have_field('タグ')

        # ボタンが表示されることを確認
        expect(page).to have_button('更新')
        expect(page).to have_button('キャンセル')
      end
    end
  end

  private

  def open_edit_modal
    # 編集APIのモック
    stub_request(:get, %r{/short_urls/test123/edit})
      .to_return(
        status: 200,
        body: turbo_stream_edit_response,
        headers: { 'Content-Type' => 'text/vnd.turbo-stream.html' }
      )

    # 編集ボタンをクリック
    within("#short-url-card-#{short_url.short_code}") do
      find('button[title="編集"]').click
    end

    # モーダルが表示されるまで待機
    expect(page).to have_content('短縮URL編集')
  end

  def turbo_stream_edit_response
    <<~HTML
      <turbo-stream action="update" target="edit-modal">
        <template>
          <div class="fixed inset-0 z-50 overflow-y-auto flex items-center justify-center p-4">
            <div class="bg-white rounded-2xl shadow-2xl max-w-2xl w-full">
              <div class="p-6">
                <h3 class="text-xl font-bold text-gray-900">短縮URL編集</h3>
                <form>
                  <div>
                    <label for="edit_short_url_form_title">タイトル</label>
                    <input type="text" name="edit_short_url_form[title]" id="edit_short_url_form_title" value="Original Title">
                  </div>
                  <div>
                    <label for="edit_short_url_form_long_url">元のURL</label>
                    <input type="url" name="edit_short_url_form[long_url]" id="edit_short_url_form_long_url" value="https://original.example.com">
                  </div>
                  <div>
                    <label for="edit_short_url_form_tags">タグ</label>
                    <input type="text" name="edit_short_url_form[tags]" id="edit_short_url_form_tags" value="original-tag">
                  </div>
                  <div>
                    <label for="edit_short_url_form_max_visits">訪問制限</label>
                    <input type="number" name="edit_short_url_form[max_visits]" id="edit_short_url_form_max_visits" value="50">
                  </div>
                  <div class="flex items-center justify-end space-x-3">
                    <button type="button" onclick="closeEditModal()">キャンセル</button>
                    <button type="submit">更新</button>
                  </div>
                </form>
              </div>
            </div>
          </div>
        </template>
      </turbo-stream>
    HTML
  end

  def shlink_update_response
    {
      'shortCode' => 'test123',
      'shortUrl' => "https://shlink.example.com/test123",
      'longUrl' => 'https://updated.example.com',
      'title' => 'Updated Title',
      'tags' => [ 'updated-tag1', 'updated-tag2' ],
      'meta' => {},
      'maxVisits' => 100
    }
  end
end
