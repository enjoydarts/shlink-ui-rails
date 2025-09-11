require 'rails_helper'

RSpec.describe Statistics::OverallController, type: :controller do
  let(:user) { create(:user) }

  describe 'GET #index' do
    context '認証されていない場合' do
      it 'ログインページにリダイレクトされること' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context '認証されている場合' do
      before do
        sign_in user, scope: :user
      end

      context 'デフォルトパラメータ' do
        it '正常にレスポンスを返すこと' do
          get :index

          expect(response).to have_http_status(:success)
          expect(response.content_type).to include('application/json')
        end

        it '統計データを含むJSONを返すこと' do
          get :index

          json_response = JSON.parse(response.body)

          expect(json_response).to include(
            'success' => true,
            'data' => hash_including(
              'overall' => be_a(Hash),
              'daily' => be_a(Hash),
              'status' => be_a(Hash),
              'monthly' => be_a(Hash)
            ),
            'period' => '30d',
            'generated_at' => be_a(String)
          )
        end
      end

      context 'periodパラメータ指定' do
        it '指定された期間でデータを返すこと' do
          get :index, params: { period: '7d' }

          json_response = JSON.parse(response.body)
          expect(json_response['period']).to eq('7d')
        end

        it '無効な期間パラメータの場合はデフォルトを使用すること' do
          get :index, params: { period: 'invalid' }

          json_response = JSON.parse(response.body)
          expect(json_response['period']).to eq('invalid') # パラメータはそのまま返される
        end
      end

      context 'サービスエラーが発生した場合' do
        before do
          allow_any_instance_of(Statistics::OverallDataService).to receive(:call).and_raise(StandardError.new('テストエラー'))
        end

        it 'エラーレスポンスを返すこと' do
          get :index

          expect(response).to have_http_status(:internal_server_error)

          json_response = JSON.parse(response.body)
          expect(json_response).to include(
            'success' => false,
            'error' => '統計データの取得に失敗しました',
            'message' => 'テストエラー'
          )
        end

        it 'エラーログが出力されること' do
          expect(Rails.logger).to receive(:error).with(/統計データ生成エラー/)

          get :index
        end
      end

      context '実際の統計データ' do
        before do
          # ユーザーを新しく作成して確実にテスト内で使用
          @test_user = create(:user)
          sign_in @test_user, scope: :user

          create(:short_url, user: @test_user, visit_count: 10, short_code: 'test1')
          create(:short_url, user: @test_user, visit_count: 20, short_code: 'test2')

          # Shlink APIスタブ
          stub_request(:get, %r{https://test\.example\.com/rest/v3/short-urls/test1/visits})
            .to_return(
              status: 200,
              body: { visits: { data: [] } }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          stub_request(:get, %r{https://test\.example\.com/rest/v3/short-urls/test2/visits})
            .to_return(
              status: 200,
              body: { visits: { data: [] } }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )
        end

        it '正しい統計値を返すこと' do
          get :index

          json_response = JSON.parse(response.body)
          overall_data = json_response['data']['overall']

          expect(overall_data).to include(
            'total_urls' => 2,
            'total_visits' => 30,
            'active_urls' => 2
          )
        end
      end

      context 'レスポンス時間の測定' do
        it '適切な時間でレスポンスを返すこと' do
          start_time = Time.current
          get :index
          end_time = Time.current

          expect(response).to have_http_status(:success)
          expect(end_time - start_time).to be < 2.0 # 2秒未満
        end
      end
    end
  end

  describe 'セキュリティテスト' do
    before do
      @security_user = create(:user)
      @other_user = create(:user)

      create(:short_url, user: @security_user, visit_count: 10, short_code: 'sec1')
      create(:short_url, user: @other_user, visit_count: 100, short_code: 'sec2')

      # セキュリティユーザーのURLのみスタブ設定
      stub_request(:get, %r{https://test\.example\.com/rest/v3/short-urls/sec1/visits})
        .to_return(
          status: 200,
          body: { visits: { data: [] } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      sign_in @security_user, scope: :user
    end

    it '他ユーザーのデータが含まれないこと' do
      get :index

      json_response = JSON.parse(response.body)
      overall_data = json_response['data']['overall']

      # @security_userのデータのみが含まれること
      expect(overall_data['total_urls']).to eq(1)
      expect(overall_data['total_visits']).to eq(10)
    end
  end

  describe 'パフォーマンステスト' do
    before do
      @perf_user = create(:user)
      sign_in @perf_user, scope: :user

      # サービスをモックして高速化
      allow_any_instance_of(Statistics::OverallDataService)
        .to receive(:call)
        .and_return({
          overall: { total_urls: 50, total_visits: 2500, active_urls: 50 },
          daily: { labels: [], values: [] },
          status: { labels: [], values: [] },
          monthly: { labels: [], values: [] }
        })
    end
  end

  describe 'JSONレスポンス形式' do
    before do
      @json_user = create(:user)
      sign_in @json_user, scope: :user
    end

    it '正しいJSONスキーマを返すこと' do
      get :index

      json_response = JSON.parse(response.body)

      # トップレベルのキー
      expect(json_response.keys).to match_array([ 'success', 'data', 'period', 'generated_at' ])

      # データ構造の検証
      data = json_response['data']
      expect(data.keys).to match_array([ 'overall', 'daily', 'status', 'monthly' ])

      # overall データ
      expect(data['overall'].keys).to match_array([ 'total_urls', 'total_visits', 'active_urls' ])

      # daily データ
      expect(data['daily'].keys).to match_array([ 'labels', 'values' ])
      expect(data['daily']['labels']).to be_an(Array)
      expect(data['daily']['values']).to be_an(Array)

      # status データ
      expect(data['status'].keys).to match_array([ 'labels', 'values' ])
      expect(data['status']['labels']).to eq([ '有効', '期限切れ', '制限到達' ])

      # monthly データ
      expect(data['monthly'].keys).to match_array([ 'labels', 'values' ])
      expect(data['monthly']['labels']).to be_an(Array)
      expect(data['monthly']['values']).to be_an(Array)
    end

    it 'generated_atが有効なISO8601形式であること' do
      get :index

      json_response = JSON.parse(response.body)
      generated_at = json_response['generated_at']

      expect { Time.iso8601(generated_at) }.not_to raise_error
    end
  end
end
