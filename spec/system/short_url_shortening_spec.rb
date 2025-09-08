require 'rails_helper'

RSpec.describe 'URL短縮機能', type: :system do
  let!(:user) { create(:user) }

  before do
    driven_by(:rack_test)
    sign_in user, scope: :user
  end

  describe 'ダッシュボード' do
    it 'URL短縮インターフェースを表示する' do
      visit dashboard_path

      expect(page).to have_content('URL短縮ツール')
      expect(page).to have_content('長いURLを瞬時に短縮して、共有を簡単にします')
      expect(page).to have_button('短縮する')
    end

    it '機能説明を表示する' do
      visit dashboard_path

      expect(page).to have_content('高速処理')
      expect(page).to have_content('安全・確実')
      expect(page).to have_content('カスタマイズ')
    end
  end

  describe 'フォーム送信' do
    let(:shlink_response) do
      {
        'shortUrl' => 'https://kty.at/abc123',
        'shortCode' => 'abc123',
        'longUrl' => 'https://example.com/very/long/url',
        'dateCreated' => '2025-01-01T00:00:00+00:00'
      }
    end

    context '有効なURLの場合' do
      before do
        allow_any_instance_of(Shlink::CreateShortUrlService).to receive(:call)
          .and_return(shlink_response)
      end

      it '送信成功時に結果を表示する' do
        visit dashboard_path

        fill_in 'shorten_form[long_url]', with: 'https://example.com'
        click_button '短縮する'

        expect(page).to have_content('URL短縮ツール')
        # フラッシュメッセージが表示される
        expect(page).to have_content('短縮しました')
      end
    end

    context '無効なURLの場合' do
      it 'バリデーションエラーを表示する' do
        visit dashboard_path

        fill_in 'shorten_form[long_url]', with: 'invalid-url'
        click_button '短縮する'

        expect(page).to have_content('は無効なURLです')
      end
    end

    context '空のURLの場合' do
      it 'バリデーションエラーを表示する' do
        visit dashboard_path

        fill_in 'shorten_form[long_url]', with: ''
        click_button '短縮する'

        expect(page).to have_content('を入力してください')
      end
    end
  end

  describe 'タグ機能（高度なオプション）' do
    let(:shlink_response_with_tags) do
      {
        'shortUrl' => 'https://kty.at/abc123',
        'shortCode' => 'abc123',
        'longUrl' => 'https://example.com/very/long/url',
        'dateCreated' => '2025-01-01T00:00:00+00:00',
        'tags' => [ 'tag1', 'tag2', 'tag3' ]
      }
    end

    before do
      allow_any_instance_of(Shlink::CreateShortUrlService).to receive(:call)
        .and_return(shlink_response_with_tags)
    end

    it '高度なオプションとしてタグ入力フィールドが存在する' do
      visit dashboard_path

      expect(page).to have_content('高度なオプション')
      # 高度なオプションを開く
      page.find('button[data-action="click->accordion#toggle"]').click
      expect(page).to have_field('shorten_form[tags]', type: 'hidden')
      expect(page).to have_css('input[data-tag-input-target="input"]')
    end

    it 'タグ付きでURL短縮ができる' do
      visit dashboard_path

      fill_in 'shorten_form[long_url]', with: 'https://example.com'

      # 高度なオプションを開く
      page.find('button[data-action="click->accordion#toggle"]').click

      # タグを隠しフィールドに直接設定（rack_testドライバ対応）
      tag_field = page.find('input[data-tag-input-target="hiddenInput"]', visible: false)
      tag_field.set('tag1, tag2, tag3')

      click_button '短縮する'

      expect(page).to have_content('短縮しました')
    end

    it 'タグ入力時の説明が表示される' do
      visit dashboard_path

      # 高度なオプションを開く
      page.find('button[data-action="click->accordion#toggle"]').click

      expect(page).to have_content('Enterキーでタグを確定（最大10個、各20文字以内）')
    end
  end

  describe 'エラーハンドリング' do
    context 'Shlink APIがエラーを返す場合' do
      before do
        allow_any_instance_of(Shlink::CreateShortUrlService).to receive(:call)
          .and_raise(Shlink::Error, 'API connection failed')
      end

      it 'APIエラーメッセージを表示する' do
        visit dashboard_path

        fill_in 'shorten_form[long_url]', with: 'https://example.com'
        click_button '短縮する'

        expect(page).to have_content('API connection failed')
      end
    end
  end
end
