require 'rails_helper'

RSpec.describe Shlink::SyncShortUrlsService do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user) }

  before do
    # SystemSettingのモック設定（包括的なモックでデフォルト値を返す）
    allow(SystemSetting).to receive(:get).and_call_original
    allow(SystemSetting).to receive(:get).with("performance.items_per_page", 20).and_return(100)
    allow(SystemSetting).to receive(:get).with("security.require_strong_password", true).and_return(false)
  end

  describe "#call" do
    let(:mock_list_service) { instance_double(Shlink::ListShortUrlsService) }
    let(:short_urls_data) do
      [
        {
          "shortCode" => "abc123",
          "shortUrl" => "https://s.test/abc123",
          "longUrl" => "https://example.com/test",
          "domain" => "s.test",
          "title" => "Test Page",
          "tags" => [ "tag1", "tag2" ],
          "meta" => {
            "description" => "Test URL",
            "validSince" => "2023-01-01T00:00:00Z",
            "validUntil" => "2023-12-31T23:59:59Z",
            "maxVisits" => 100
          },
          "visitsSummary" => { "total" => 5 },
          "crawlable" => true,
          "forwardQuery" => true,
          "dateCreated" => "2023-01-01T00:00:00Z"
        },
        {
          "shortCode" => "def456",
          "shortUrl" => "https://s.test/def456",
          "longUrl" => "https://example.com/another",
          "domain" => "s.test",
          "title" => nil,
          "tags" => nil,
          "meta" => nil,
          "visitsSummary" => { "total" => 10 },
          "crawlable" => false,
          "forwardQuery" => false,
          "dateCreated" => "2023-01-02T00:00:00Z"
        }
      ]
    end

    let(:api_response_page_1) do
      {
        "shortUrls" => {
          "data" => short_urls_data,
          "pagination" => {
            "currentPage" => 1,
            "pagesCount" => 1,
            "itemsPerPage" => 100,
            "itemsInCurrentPage" => 2,
            "totalItems" => 2
          }
        }
      }
    end

    let(:api_response_page_2) do
      {
        "shortUrls" => {
          "data" => [],
          "pagination" => {
            "currentPage" => 2,
            "pagesCount" => 1,
            "itemsPerPage" => 100,
            "itemsInCurrentPage" => 0,
            "totalItems" => 2
          }
        }
      }
    end

    before do
      allow(Shlink::ListShortUrlsService).to receive(:new).and_return(mock_list_service)
      allow(mock_list_service).to receive(:call).with(page: 1, items_per_page: 100).and_return(api_response_page_1)
      allow(mock_list_service).to receive(:call).with(page: 2, items_per_page: 100).and_return(api_response_page_2)

      # sync_redirect_rules_from_apiのモックを無効化
      allow_any_instance_of(ShortUrl).to receive(:sync_redirect_rules_from_api).and_call_original

      # redirect-rulesエンドポイントのWebMockスタブ
      WebMock.stub_request(:get, %r{https://[^/]+/rest/v\d+/short-urls/[^/]+/redirect-rules})
        .to_return(
          status: 200,
          body: {
            defaultLongUrl: "https://example.com",
            redirectRules: []
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    context "既存URLが存在し新しいデータで更新される場合" do
      let!(:existing_url1) { create(:short_url, user: user, short_code: "abc123", visit_count: 0) }
      let!(:existing_url2) { create(:short_url, user: user, short_code: "def456", visit_count: 0) }

      it "既存の短縮URLを更新すること" do
        expect { service.call }.not_to change(user.short_urls, :count)
      end

      it "正しい属性で短縮URLを更新すること" do
        service.call

        existing_url1.reload
        expect(existing_url1).to have_attributes(
          title: "Test Page",
          visit_count: 5
        )
        expect(existing_url1.tags).to eq('["tag1","tag2"]')
        expect(existing_url1.meta).to eq('{"description":"Test URL","validSince":"2023-01-01T00:00:00Z","validUntil":"2023-12-31T23:59:59Z","maxVisits":100}')
        expect(existing_url1.valid_until).to be_present

        existing_url2.reload
        expect(existing_url2).to have_attributes(
          title: nil,
          visit_count: 10
        )
        expect(existing_url2.tags).to be_nil
        expect(existing_url2.meta).to be_nil
        expect(existing_url2.valid_until).to be_nil
      end

      it "同期した件数を返すこと" do
        result = service.call
        expect(result).to eq(2)
      end
    end

    context "既存の短縮URLがある場合" do
      let!(:existing_url) do
        create(:short_url,
               user: user,
               short_code: "abc123",
               visit_count: 0)
      end

      it "短縮URLを更新すること" do
        expect { service.call }.not_to change(user.short_urls, :count)

        existing_url.reload
        expect(existing_url.visit_count).to eq(5)
        expect(existing_url.title).to eq("Test Page")
      end
    end

    context "複数ページがある場合" do
      let(:api_response_page_1_multi) do
        {
          "shortUrls" => {
            "data" => [ short_urls_data[0] ],
            "pagination" => {
              "currentPage" => 1,
              "pagesCount" => 2,
              "itemsPerPage" => 1,
              "itemsInCurrentPage" => 1,
              "totalItems" => 2
            }
          }
        }
      end

      let(:api_response_page_2_multi) do
        {
          "shortUrls" => {
            "data" => [ short_urls_data[1] ],
            "pagination" => {
              "currentPage" => 2,
              "pagesCount" => 2,
              "itemsPerPage" => 1,
              "itemsInCurrentPage" => 1,
              "totalItems" => 2
            }
          }
        }
      end

      before do
        allow(mock_list_service).to receive(:call).with(page: 1, items_per_page: 100).and_return(api_response_page_1_multi)
        allow(mock_list_service).to receive(:call).with(page: 2, items_per_page: 100).and_return(api_response_page_2_multi)
      end

      it "全ページを処理すること" do
        # 既存のURLが2つあることを確認してからテスト
        existing_url1 = create(:short_url, user: user, short_code: "abc123", visit_count: 0)
        existing_url2 = create(:short_url, user: user, short_code: "def456", visit_count: 0)

        expect { service.call }.not_to change(user.short_urls, :count)

        existing_url1.reload
        existing_url2.reload
        expect(existing_url1.visit_count).to eq(5)
        expect(existing_url2.visit_count).to eq(10)
      end
    end

    context "APIエラーの場合" do
      let!(:existing_url) { create(:short_url, user: user, short_code: "abc123") }

      before do
        allow(mock_list_service).to receive(:call).and_raise(Shlink::Error, "API Error")
      end

      it "エラーをログに記録して例外を再発生させること" do
        expect(Rails.logger).to receive(:error).with(/Failed to sync short URLs for user \d+: API Error/)
        expect { service.call }.to raise_error(Shlink::Error, "API Error")
      end
    end

    context "不正な日付フォーマットの場合" do
      let!(:existing_url) { create(:short_url, user: user, short_code: "abc123") }

      let(:invalid_date_data) do
        [
          {
            "shortCode" => "abc123",
            "shortUrl" => "https://s.test/abc123",
            "longUrl" => "https://example.com/test",
            "domain" => "s.test",
            "dateCreated" => "invalid-date",
            "visitsSummary" => { "total" => 5 }
          }
        ]
      end

      let(:api_response_invalid_date) do
        {
          "shortUrls" => {
            "data" => invalid_date_data,
            "pagination" => {
              "currentPage" => 1,
              "pagesCount" => 1,
              "itemsPerPage" => 100,
              "itemsInCurrentPage" => 1,
              "totalItems" => 1
            }
          }
        }
      end

      before do
        allow(mock_list_service).to receive(:call).and_return(api_response_invalid_date)
      end

      it "エラーにならずに処理を続行すること" do
        expect { service.call }.not_to change(user.short_urls, :count)

        existing_url.reload
        expect(existing_url.visit_count).to eq(5)
        # 不正な日付は現在時刻が維持されること
        expect(existing_url.date_created).to be_within(1.minute).of(Time.current)
      end
    end

    context "APIから削除されたURLの場合" do
      let!(:existing_url1) { create(:short_url, user: user, short_code: "abc123", visit_count: 5) }
      let!(:existing_url2) { create(:short_url, user: user, short_code: "missing", visit_count: 3) }

      let(:api_response_missing_url) do
        {
          "shortUrls" => {
            "data" => [ short_urls_data[0] ], # abc123のみ返す（missingは含まない）
            "pagination" => {
              "currentPage" => 1,
              "pagesCount" => 1,
              "itemsPerPage" => 100,
              "itemsInCurrentPage" => 1,
              "totalItems" => 1
            }
          }
        }
      end

      before do
        allow(mock_list_service).to receive(:call).and_return(api_response_missing_url)
        # APIからの個別URL確認をモック
        allow(service).to receive(:verify_url_existence).with("abc123").and_return(true)
        allow(service).to receive(:verify_url_existence).with("missing").and_return(false)

        # redirect-rulesエンドポイントのWebMockスタブ
        WebMock.stub_request(:get, %r{https://[^/]+/rest/v\d+/short-urls/[^/]+/redirect-rules})
          .to_return(
            status: 200,
            body: {
              defaultLongUrl: "https://example.com",
              redirectRules: []
            }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "存在しないURLをソフト削除すること" do
        expect { service.call }.not_to change(user.short_urls, :count)

        existing_url1.reload
        existing_url2.reload

        expect(existing_url1.deleted_at).to be_nil
        expect(existing_url2.deleted_at).to be_present
      end

      it "削除されたURLの統計情報をログに記録すること" do
        allow(Rails.logger).to receive(:info) # その他のログを許可
        expect(Rails.logger).to receive(:info).with(/Soft deleted missing short URL: missing for user/)
        service.call
      end

      it "同期と削除の件数を正しく返すこと" do
        result = service.call
        expect(result).to eq(1) # abc123のみ同期
      end
    end

    context "個別URL確認でエラーが発生する場合" do
      let!(:existing_url) { create(:short_url, user: user, short_code: "error_url", visit_count: 5) }

      let(:api_response_empty) do
        {
          "shortUrls" => {
            "data" => [],
            "pagination" => {
              "currentPage" => 1,
              "pagesCount" => 1,
              "itemsPerPage" => 100,
              "itemsInCurrentPage" => 0,
              "totalItems" => 0
            }
          }
        }
      end

      before do
        allow(mock_list_service).to receive(:call).and_return(api_response_empty)
        allow(service).to receive(:verify_url_existence).with("error_url").and_raise(StandardError, "Network error")
      end

      it "エラー時はURLを削除せずに処理を続行すること" do
        expect(Rails.logger).to receive(:warn).with(/Failed to sync short URL error_url for user/)

        expect { service.call }.not_to change(user.short_urls, :count)

        existing_url.reload
        expect(existing_url.deleted_at).to be_nil
      end
    end

    context "既存URLが存在しない場合" do
      it "処理を早期終了すること" do
        expect(Rails.logger).to receive(:info).with(/User \d+ has no existing active short URLs to sync/)
        result = service.call
        expect(result).to eq(0)
      end
    end
  end

  describe "#verify_url_existence" do
    let(:mock_conn) { double('connection') }

    before do
      allow(service).to receive(:conn).and_return(mock_conn)
      allow(service).to receive(:api_headers).and_return({})
    end

    context "URLが存在する場合" do
      it "trueを返すこと" do
        allow(mock_conn).to receive(:get).and_return(double(status: 200))
        expect(service.send(:verify_url_existence, "abc123")).to be true
      end
    end

    context "URLが存在しない場合" do
      it "falseを返すこと" do
        allow(mock_conn).to receive(:get).and_return(double(status: 404))
        expect(service.send(:verify_url_existence, "missing")).to be false
      end
    end

    context "予期しないレスポンスの場合" do
      it "警告をログに記録してtrueを返すこと" do
        response = double(status: 500, body: "Internal Server Error")
        allow(mock_conn).to receive(:get).and_return(response)
        expect(Rails.logger).to receive(:warn).with(/Unexpected response status 500 for URL test: Internal Server Error/)

        expect(service.send(:verify_url_existence, "test")).to be true
      end
    end

    context "例外が発生する場合" do
      it "警告をログに記録してtrueを返すこと" do
        allow(mock_conn).to receive(:get).and_raise(StandardError, "Network error")
        expect(Rails.logger).to receive(:warn).with(/Failed to verify URL existence for test: Network error/)

        expect(service.send(:verify_url_existence, "test")).to be true
      end
    end
  end
end
