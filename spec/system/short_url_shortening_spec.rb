require 'rails_helper'

RSpec.describe 'URL短縮機能', type: :system do
  before do
    driven_by(:rack_test)
  end

  describe 'ホームページ' do
    it 'URL短縮インターフェースを表示する' do
      visit root_path

      expect(page).to have_content('URL短縮ツール')
      expect(page).to have_content('長いURLを瞬時に短縮して、共有を簡単にします')
      expect(page).to have_button('短縮する')
    end

    it '機能説明を表示する' do
      visit root_path

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
        allow_any_instance_of(Shlink::Client).to receive(:create_short_url)
          .with('https://example.com', '')
          .and_return(shlink_response)
      end

      it '送信成功時にルートにリダイレクトする' do
        visit root_path
        
        fill_in 'shorten_form[long_url]', with: 'https://example.com'
        click_button '短縮する'

        expect(current_path).to eq(root_path)
        expect(page).to have_content('URL短縮ツール')
      end
    end

    context '無効なURLの場合' do
      it 'バリデーションエラーを表示する' do
        visit root_path
        
        fill_in 'shorten_form[long_url]', with: 'invalid-url'
        click_button '短縮する'

        expect(page).to have_content('is invalid')
        expect(page).to have_http_status(:unprocessable_entity)
      end
    end

    context '空のURLの場合' do
      it 'バリデーションエラーを表示する' do
        visit root_path
        
        fill_in 'shorten_form[long_url]', with: ''
        click_button '短縮する'

        expect(page).to have_content("can't be blank")
        expect(page).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'エラーハンドリング' do
    context 'Shlink APIがエラーを返す場合' do
      before do
        allow_any_instance_of(Shlink::Client).to receive(:create_short_url)
          .and_raise(Shlink::Error, 'API connection failed')
      end

      it 'APIエラーメッセージを表示する' do
        visit root_path
        
        fill_in 'shorten_form[long_url]', with: 'https://example.com'
        click_button '短縮する'

        expect(page).to have_content('API connection failed')
        expect(page).to have_http_status(:bad_gateway)
      end
    end
  end
end