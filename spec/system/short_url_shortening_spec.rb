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
