require 'rails_helper'

RSpec.describe MypageController, type: :request do
  let(:user) { create(:user) }

  describe "POST #sync" do
    before { sign_in user, scope: :user }

    context "同期が成功した場合" do
      let(:mock_sync_service) { instance_double(Shlink::SyncShortUrlsService) }

      before do
        allow(Shlink::SyncShortUrlsService).to receive(:new).with(user).and_return(mock_sync_service)
        allow(mock_sync_service).to receive(:call).and_return(3)
      end

      it "正常なJSONレスポンスを返すこと" do
        post mypage_sync_path

        expect(response).to have_http_status(:success)
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['message']).to eq('3件の短縮URLを同期しました')
        expect(json_response['synced_count']).to eq(3)
      end

      it "同期サービスが呼び出されること" do
        post mypage_sync_path

        expect(Shlink::SyncShortUrlsService).to have_received(:new).with(user)
        expect(mock_sync_service).to have_received(:call)
      end
    end

    context "Shlink APIエラーが発生した場合" do
      let(:mock_sync_service) { instance_double(Shlink::SyncShortUrlsService) }
      let(:error_message) { "API connection failed" }

      before do
        allow(Shlink::SyncShortUrlsService).to receive(:new).with(user).and_return(mock_sync_service)
        allow(mock_sync_service).to receive(:call).and_raise(Shlink::Error, error_message)
        allow(Rails.logger).to receive(:error)
      end

      it "エラーレスポンスを返すこと" do
        post mypage_sync_path

        expect(response).to have_http_status(:bad_gateway)
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['message']).to eq("同期に失敗しました: #{error_message}")
      end

      it "エラーログが記録されること" do
        post mypage_sync_path

        expect(Rails.logger).to have_received(:error).with(/Sync failed for user #{user.id}/)
      end
    end

    context "予期しないエラーが発生した場合" do
      let(:mock_sync_service) { instance_double(Shlink::SyncShortUrlsService) }

      before do
        allow(Shlink::SyncShortUrlsService).to receive(:new).with(user).and_return(mock_sync_service)
        allow(mock_sync_service).to receive(:call).and_raise(StandardError, "Unexpected error")
        allow(Rails.logger).to receive(:error)
      end

      it "汎用エラーレスポンスを返すこと" do
        post mypage_sync_path

        expect(response).to have_http_status(:internal_server_error)
        expect(response.content_type).to include('application/json')

        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['message']).to eq("予期しないエラーが発生しました")
      end

      it "エラーログが記録されること" do
        post mypage_sync_path

        expect(Rails.logger).to have_received(:error).with(/Unexpected error during sync for user #{user.id}/)
      end
    end

    context "認証されていない場合" do
      before { sign_out :user }

      it "リダイレクトされること" do
        post mypage_sync_path

        expect(response).to have_http_status(:redirect)
      end
    end
  end
end
