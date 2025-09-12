require 'rails_helper'

RSpec.describe Statistics::IndividualController, type: :request do
  let(:user) { create(:user) }
  let!(:short_url) { create(:short_url, user: user, short_code: 'abc123') }

  before { sign_in user, scope: :user }

  describe 'GET #show' do
    context '認証されている場合' do
      before do
        # Mock statistics service
        allow_any_instance_of(Statistics::IndividualUrlDataService)
          .to receive(:call)
          .and_return({
            total_visits: 100,
            unique_visitors: 50,
            daily_visits: { labels: [ '01/01' ], values: [ 10 ] },
            hourly_visits: { labels: [ '0時' ], values: [ 5 ] },
            browser_stats: { labels: [ 'Chrome' ], values: [ 20 ] },
            country_stats: { labels: [ 'Japan' ], values: [ 15 ] },
            referer_stats: { labels: [ 'Direct' ], values: [ 25 ] }
          })
      end

      it 'JSON形式で統計データを返すこと' do
        get "/statistics/individual/abc123", params: { period: '30d' }

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']).to include('total_visits')
      end

      context '他ユーザーのURLの場合' do
        let(:other_user) { create(:user) }
        let!(:other_url) { create(:short_url, user: other_user, short_code: 'xyz789') }

        it '404エラーを返すこと' do
          get "/statistics/individual/xyz789", params: { period: '30d' }

          expect(response).to have_http_status(:not_found)
          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be false
        end
      end

      context '存在しないshort_codeの場合' do
        it '404エラーを返すこと' do
          get "/statistics/individual/nonexistent", params: { period: '30d' }

          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context '認証されていない場合' do
      it 'ログインページにリダイレクトすること' do
        logout :user
        get "/statistics/individual/abc123", params: { period: '30d' }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET #url_list' do
    context '認証されている場合' do
      let!(:url1) { create(:short_url, user: user, short_code: 'abc1', title: 'Test URL 1') }
      let!(:url2) { create(:short_url, user: user, short_code: 'abc2', title: 'Test URL 2') }

      it 'JSON形式でURL一覧を返すこと' do
        get "/statistics/url_list"

        expect(response).to have_http_status(:success)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['urls']).to be_an(Array)
        expect(json_response['urls'].length).to be >= 2
      end

      it 'タイトルと短縮URLを含むこと' do
        get "/statistics/url_list"

        json_response = JSON.parse(response.body)
        url_data = json_response['urls'].first
        expect(url_data).to include('short_code', 'title', 'short_url', 'long_url', 'visit_count')
      end
    end

    context '認証されていない場合' do
      before { sign_out :user }
      
      it 'ログインページにリダイレクトすること' do
        get statistics_url_list_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
