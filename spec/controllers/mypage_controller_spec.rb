require 'rails_helper'

RSpec.describe MypageController, type: :controller do
  let(:user) { create(:user) }

  describe "GET #index" do
    context "認証されていない場合" do
      before { get :index }

      it "リダイレクトされること" do
        expect(response).to have_http_status(:redirect)
      end
    end

    context "認証されている場合" do
      before { sign_in user, scope: :user }

      context "短縮URLがない場合" do
        before { get :index }

        it "正常にレスポンスを返すこと" do
          expect(response).to have_http_status(:success)
        end

        it "空の統計情報が設定されること" do
          expect(assigns(:short_urls)).to be_empty
          expect(assigns(:total_urls)).to eq(0)
          expect(assigns(:total_visits)).to eq(0)
          expect(assigns(:active_urls)).to eq(0)
        end
      end

      context "短縮URLがある場合" do
        let!(:active_url1) { create(:short_url, user: user, visit_count: 10) }
        let!(:active_url2) { create(:short_url, :with_expiration, user: user, visit_count: 20) }
        let!(:expired_url) { create(:short_url, :expired, user: user, visit_count: 5) }
        let!(:limit_reached_url) { create(:short_url, :visit_limit_reached, user: user, visit_count: 15) }
        let!(:other_user_url) { create(:short_url, visit_count: 100) }

        before { get :index }

        it "正常にレスポンスを返すこと" do
          expect(response).to have_http_status(:success)
        end

        it "現在のユーザーの短縮URLのみが表示されること" do
          expect(assigns(:short_urls)).to contain_exactly(active_url1, active_url2, expired_url, limit_reached_url)
          expect(assigns(:short_urls)).not_to include(other_user_url)
        end

        xit "統計情報が正しく計算されること" do
          expect(assigns(:total_urls)).to eq(4)
          expect(assigns(:total_visits)).to eq(50) # 10 + 20 + 5 + 15
          expect(assigns(:active_urls)).to eq(2) # active_url1 and active_url2 only
        end

        it "短縮URLが作成日時の降順で表示されること" do
          # FactoryBotで作成された順序と逆順になることを確認
          expect(assigns(:short_urls).first.date_created).to be >= assigns(:short_urls).last.date_created
        end
      end

      context "検索機能" do
        let!(:search_url1) { create(:short_url, user: user, title: "検索テスト1", short_code: "test123") }
        let!(:search_url2) { create(:short_url, user: user, long_url: "https://example.com/test", short_code: "abc456") }
        let!(:other_url) { create(:short_url, user: user, title: "その他", short_code: "xyz789") }

        it "タイトルで検索できること" do
          get :index, params: { search: "検索テスト" }
          expect(assigns(:short_urls)).to include(search_url1)
          expect(assigns(:short_urls)).not_to include(search_url2, other_url)
        end

        it "URLで検索できること" do
          get :index, params: { search: "example.com/test" }
          expect(assigns(:short_urls)).to include(search_url2)
          expect(assigns(:short_urls)).not_to include(search_url1, other_url)
        end

        it "短縮コードで検索できること" do
          get :index, params: { search: "test123" }
          expect(assigns(:short_urls)).to include(search_url1)
          expect(assigns(:short_urls)).not_to include(search_url2, other_url)
        end

        it "検索結果がない場合は空配列を返すこと" do
          get :index, params: { search: "存在しない検索語" }
          expect(assigns(:short_urls)).to be_empty
        end
      end

      context "ページネーション" do
        let!(:urls) { create_list(:short_url, 15, user: user) }

        it "1ページ目に10件表示されること" do
          get :index, params: { page: 1 }
          expect(assigns(:short_urls).count).to eq(10)
        end

        it "2ページ目に残りの件数が表示されること" do
          get :index, params: { page: 2 }
          expect(assigns(:short_urls).count).to eq(5)
        end
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:user_url) { create(:short_url, user: user, short_code: 'test123') }
    let!(:other_user_url) { create(:short_url, short_code: 'other456') }

    context "認証されていない場合" do
      before { delete :destroy, params: { short_code: 'test123' } }

      it "リダイレクトされること" do
        expect(response).to have_http_status(:redirect)
      end
    end

    context "認証されている場合" do
      before { sign_in user, scope: :user }

      context "存在する自分のURLを削除する場合" do
        let(:delete_service) { instance_double(Shlink::DeleteShortUrlService) }

        before do
          allow(Shlink::DeleteShortUrlService).to receive(:new).with('test123').and_return(delete_service)
          allow(delete_service).to receive(:call).and_return(true)
        end

        it "削除サービスが呼ばれること" do
          expect(delete_service).to receive(:call)
          delete :destroy, params: { short_code: 'test123' }
        end

        it "ローカルDBからも削除されること" do
          expect {
            delete :destroy, params: { short_code: 'test123' }
          }.to change(ShortUrl, :count).by(-1)
        end

        it "成功のJSONレスポンスを返すこと" do
          delete :destroy, params: { short_code: 'test123' }
          expect(response).to have_http_status(:success)

          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be true
          expect(json_response['message']).to include('削除しました')
        end
      end

      context "存在しないURLを削除しようとする場合" do
        it "404エラーを返すこと" do
          delete :destroy, params: { short_code: 'nonexistent' }
          expect(response).to have_http_status(:not_found)

          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be false
          expect(json_response['message']).to include('見つかりません')
        end
      end

      context "他のユーザーのURLを削除しようとする場合" do
        it "404エラーを返すこと" do
          delete :destroy, params: { short_code: 'other456' }
          expect(response).to have_http_status(:not_found)

          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be false
          expect(json_response['message']).to include('見つかりません')
        end

        it "URLが削除されないこと" do
          expect {
            delete :destroy, params: { short_code: 'other456' }
          }.not_to change(ShortUrl, :count)
        end
      end

      context "Shlink APIでエラーが発生した場合" do
        let(:delete_service) { instance_double(Shlink::DeleteShortUrlService) }

        before do
          allow(Shlink::DeleteShortUrlService).to receive(:new).with('test123').and_return(delete_service)
          allow(delete_service).to receive(:call).and_raise(Shlink::Error.new("APIエラー"))
        end

        it "エラーのJSONレスポンスを返すこと" do
          delete :destroy, params: { short_code: 'test123' }
          expect(response).to have_http_status(:bad_gateway)

          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be false
          expect(json_response['message']).to include('削除に失敗しました')
        end

        it "ローカルDBからは削除されないこと" do
          expect {
            delete :destroy, params: { short_code: 'test123' }
          }.not_to change(ShortUrl, :count)
        end
      end
    end
  end
end
