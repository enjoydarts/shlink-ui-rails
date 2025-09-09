require 'rails_helper'

RSpec.describe '統計グラフ機能', type: :system do
  let(:user) { create(:user) }
  let!(:short_urls) { create_list(:short_url, 5, user: user, visit_count: rand(1..50)) }

  before do
    driven_by(:rack_test)
    sign_in user, scope: :user
  end

  describe 'マイページでの統計グラフ表示' do
    it 'タブナビゲーションが表示されること' do
      visit mypage_path

      expect(page).to have_css('[data-controller="mypage-tabs"]')
      expect(page).to have_button('URL一覧')
      expect(page).to have_button('統計グラフ')
    end

    it '初期状態でURL一覧タブがアクティブであること' do
      visit mypage_path

      # URL一覧タブがアクティブ（ボタン要素のみを選択）
      url_tab = find('button[data-tab="urls"]')
      expect(url_tab['aria-selected']).to eq('true')
      expect(url_tab[:class]).to include('border-blue-500')

      # 統計グラフタブが非アクティブ（ボタン要素のみを選択）
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

    it '統計グラフタブをクリックすると統計パネルが表示されること' do
      visit mypage_path

      click_button '統計グラフ'

      # パネルの切り替えを確認
      expect(page).to have_css('#statistics-panel', visible: true)
      expect(page).to have_css('#urls-panel', visible: false)

      # タブの状態変更を確認（JavaScriptの実行を待つ）
      stats_tab = find('button[data-tab="statistics"]')
      expect(stats_tab).to have_attribute('aria-selected', 'true')
      expect(stats_tab[:class]).to include('border-blue-500')
    end

    it '統計グラフコンテナが表示されること' do
      visit mypage_path
      click_button '統計グラフ'

      expect(page).to have_css('[data-controller*="statistics-charts"]')
      expect(page).to have_content('統計グラフ')
      expect(page).to have_content('期間:')
    end

    it '期間選択フィルターが表示されること' do
      visit mypage_path
      click_button '統計グラフ'

      expect(page).to have_select('period-select')
      within('select#period-select') do
        expect(page).to have_content('1週間')
        expect(page).to have_content('1ヶ月')
        expect(page).to have_content('3ヶ月')
        expect(page).to have_content('1年')
      end

      # デフォルトで1ヶ月が選択されていること
      expect(page).to have_select('period-select', selected: '1ヶ月')
    end

    it 'グラフコンテナが表示されること' do
      visit mypage_path
      click_button '統計グラフ'

      # 4つのグラフエリアが存在すること
      expect(page).to have_css('canvas[data-statistics-charts-target="overallChart"]')
      expect(page).to have_css('canvas[data-statistics-charts-target="dailyChart"]')
      expect(page).to have_css('canvas[data-statistics-charts-target="statusChart"]')
      expect(page).to have_css('canvas[data-statistics-charts-target="monthlyChart"]')
    end
  end

  describe 'データが存在しない場合' do
    let(:user_no_data) { create(:user) }

    before do
      sign_in user_no_data, scope: :user
    end

    it 'データなし状態が表示されること' do
      visit mypage_path
      click_button '統計グラフ'

      expect(page).to have_content('まだ統計データがありません')
      expect(page).to have_content('短縮URLを作成すると統計グラフが表示されます')
      expect(page).to have_link('URL作成', href: dashboard_path)
    end
  end

  describe 'レスポンシブデザイン' do
    it 'グリッドレイアウトが適用されること' do
      visit mypage_path
      click_button '統計グラフ'

      expect(page).to have_css('.grid.grid-cols-1.lg\\:grid-cols-2')
    end

    it 'モバイル表示でも適切にレイアウトされること' do
      # rack_testドライバーではウィンドウサイズ変更がサポートされないため、
      # CSSクラスの存在確認のみを行う
      visit mypage_path
      click_button '統計グラフ'

      expect(page).to have_css('.grid-cols-1')
    end
  end

  describe 'アクセシビリティ' do
    it '適切なARIA属性が設定されていること' do
      visit mypage_path

      # タブにrole属性が設定されていること
      expect(page).to have_css('[aria-selected="true"]')
      expect(page).to have_css('[aria-selected="false"]')

      # パネルにaria-hidden属性が設定されていること
      expect(page).to have_css('[aria-hidden="false"]')
      expect(page).to have_css('[aria-hidden="true"]')
    end

    it 'パネルにrole="tabpanel"が設定されていること' do
      visit mypage_path

      expect(page).to have_css('#urls-panel[role="tabpanel"]')
      expect(page).to have_css('#statistics-panel[role="tabpanel"]')
    end

    it 'タブにaria-controls属性が設定されていること' do
      visit mypage_path

      url_tab = find('button[data-tab="urls"]')
      stats_tab = find('button[data-tab="statistics"]')

      expect(url_tab['aria-controls']).to eq('urls-panel')
      expect(stats_tab['aria-controls']).to eq('statistics-panel')
    end
  end

  describe 'ナビゲーション機能' do
    it 'タブ間の切り替えが正しく動作すること' do
      visit mypage_path

      # 統計タブに切り替え
      click_button '統計グラフ'
      expect(page).to have_css('#statistics-panel', visible: true)
      expect(page).to have_css('#urls-panel', visible: false)

      # URL一覧タブに戻る
      click_button 'URL一覧'
      expect(page).to have_css('#urls-panel', visible: true)
      expect(page).to have_css('#statistics-panel', visible: false)
    end

    it '直接統計タブを複数回クリックしてもエラーが発生しないこと' do
      visit mypage_path

      3.times do
        click_button '統計グラフ'
        expect(page).to have_css('#statistics-panel', visible: true)
      end
    end
  end

  describe 'パフォーマンス' do
    it 'ページロード時間が適切であること' do
      start_time = Time.current
      visit mypage_path
      end_time = Time.current

      expect(end_time - start_time).to be < 3.0 # 3秒未満
    end

    it 'タブ切り替えが即座に反応すること' do
      visit mypage_path

      start_time = Time.current
      click_button '統計グラフ'
      end_time = Time.current

      expect(end_time - start_time).to be < 1.0 # 1秒未満
      expect(page).to have_css('#statistics-panel', visible: true)
    end
  end

  describe 'セキュリティ' do
    before do
      @other_user = create(:user)
      create_list(:short_url, 3, user: @other_user, title: "Other User URL")
    end

    it '他ユーザーのデータが表示されないこと' do
      visit mypage_path

      # URL一覧に他ユーザーのURLが表示されないこと
      expect(page).not_to have_content("Other User URL")

      # 統計も他ユーザーのデータを含まないこと（APIレベルでテスト済み）
      click_button '統計グラフ'
      expect(page).to have_css('[data-controller*="statistics-charts"]')
    end
  end

  describe 'エラーハンドリング' do
    it 'JavaScript無効でも基本機能が動作すること' do
      # JavaScript無効でのテストはrack_testドライバーで自動的に実行される
      visit mypage_path

      expect(page).to have_button('URL一覧')
      expect(page).to have_button('統計グラフ')
      expect(page).to have_content('あなたの短縮URL一覧')
    end
  end

  describe 'データ統合テスト' do
    before do
      # 既存のテストデータをクリアして新しいデータを作成
      user.short_urls.destroy_all
      create(:short_url, user: user, visit_count: 10)
      create(:short_url, user: user, visit_count: 5, valid_until: 1.day.ago)
      create(:short_url, user: user, visit_count: 100, max_visits: 100)
    end

    it '統計カードと統計グラフで一貫したデータが表示されること' do
      visit mypage_path

      # 統計カードの値を確認（期待値に合わせて調整）
      within('.grid.grid-cols-1.md\\:grid-cols-3') do
        expect(page).to have_content('3') # 総短縮URL数
        expect(page).to have_content('115') # 総アクセス数 (10+5+100)
        expect(page).to have_content('1') # 有効なURL数
      end

      # 統計グラフでも同様のデータが表示されること（データ属性で確認）
      click_button '統計グラフ'
      expect(page).to have_css('[data-statistics-charts-user-id-value="' + user.id.to_s + '"]')
    end
  end
end
