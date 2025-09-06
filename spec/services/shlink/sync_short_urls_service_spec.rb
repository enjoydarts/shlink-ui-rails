require 'rails_helper'

RSpec.describe Shlink::SyncShortUrlsService do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user) }

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

      it "エラーをログに記録して0件の同期結果を返すこと" do
        expect(Rails.logger).to receive(:warn).with(/Failed to sync short URL abc123 for user/)
        result = service.call
        expect(result).to eq(0)
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
  end
end
