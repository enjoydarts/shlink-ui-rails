require 'rails_helper'

RSpec.describe MypageController, type: :controller do
  include Devise::Test::ControllerHelpers
  
  let(:user) { create(:user) }

  describe "GET #index" do
    context "認証されていない場合" do
      before { get :index }

      it "リダイレクトされること" do
        expect(response).to have_http_status(:redirect)
      end
    end

    context "認証されている場合" do
      before { sign_in user }

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

        it "統計情報が正しく計算されること" do
          expect(assigns(:total_urls)).to eq(4)
          expect(assigns(:total_visits)).to eq(50) # 10 + 20 + 5 + 15
          expect(assigns(:active_urls)).to eq(2) # active_url1 and active_url2 only
        end

        it "短縮URLが作成日時の降順で表示されること" do
          # FactoryBotで作成された順序と逆順になることを確認
          expect(assigns(:short_urls).first.date_created).to be >= assigns(:short_urls).last.date_created
        end
      end
    end
  end
end