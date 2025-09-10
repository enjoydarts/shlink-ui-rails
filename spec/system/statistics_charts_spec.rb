require 'rails_helper'

RSpec.describe '全体統計機能', type: :system do
  let(:user) { create(:user) }
  let!(:short_urls) { create_list(:short_url, 5, user: user, visit_count: rand(1..50)) }

  before do
    sign_in user, scope: :user
  end

  context 'JavaScript無効環境' do
    before { driven_by(:rack_test) }

    describe 'マイページでの全体統計表示' do
      it 'タブナビゲーションが表示されること' do
        visit mypage_path

        expect(page).to have_css('[data-controller="mypage-tabs"]')
        expect(page).to have_button('URL一覧')
        expect(page).to have_button('全体統計')
      end

      it '初期状態でURL一覧タブがアクティブであること' do
        visit mypage_path

        # URL一覧タブがアクティブ（ボタン要素のみを選択）
        url_tab = find('button[data-tab="urls"]')
        expect(url_tab['aria-selected']).to eq('true')
        expect(url_tab[:class]).to include('border-blue-500')

        # 全体統計タブが非アクティブ（ボタン要素のみを選択）
        stats_tab = find('button[data-tab="statistics"]')
        expect(stats_tab['aria-selected']).to eq('false')
        expect(stats_tab[:class]).to include('border-transparent')
      end

      it 'URL一覧パネルが表示されること' do
        visit mypage_path

        expect(page).to have_css('#urls-panel', visible: true)
        expect(page).to have_content('あなたの短縮URL一覧')
        expect(page).to have_css('#statistics-panel', visible: false)
      end
    end
  end

  # JavaScript有効環境は複雑なので実際の開発でテストする
  # システムテストではJavaScript無効環境での基本動作を確認

  context 'マークアップとスタイルの確認（JavaScript無効）' do
    before { driven_by(:rack_test) }

    describe '統計パネルの構造' do
      it '統計パネルが正しいマークアップを持つこと' do
        visit mypage_path

        # statistics-panelが存在する
        expect(page).to have_css('#statistics-panel')

        # 期間選択要素が存在する
        expect(page).to have_css('select#period-select')

        # グラフグリッドが存在する
        expect(page).to have_css('.grid')

        # Canvas要素が存在する
        expect(page).to have_css('canvas')

        # データコントローラーが設定されている
        expect(page).to have_css('[data-controller*="statistics-charts"]')
      end

      it '個別分析パネルの構造が正しいこと' do
        visit mypage_path

        # individual-panelが存在する
        expect(page).to have_css('#individual-panel')

        # URL選択要素が存在する
        expect(page).to have_css('[data-controller*="individual-analysis"]')
      end
    end
  end
end
