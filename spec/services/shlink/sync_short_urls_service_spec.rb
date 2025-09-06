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
          "meta" => { "description" => "Test URL" },
          "visitsSummary" => { "total" => 5 },
          "validSince" => "2023-01-01T00:00:00Z",
          "validUntil" => "2023-12-31T23:59:59Z",
          "maxVisits" => 100,
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
          "validSince" => nil,
          "validUntil" => nil,
          "maxVisits" => nil,
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

    context "新しい短縮URLの場合" do
      it "短縮URLを作成すること" do
        expect { service.call }.to change(user.short_urls, :count).by(2)
      end

      it "正しい属性で短縮URLを作成すること" do
        service.call

        first_url = user.short_urls.find_by(short_code: "abc123")
        expect(first_url).to have_attributes(
          short_url: "https://s.test/abc123",
          long_url: "https://example.com/test",
          domain: "s.test",
          title: "Test Page",
          visit_count: 5,
          max_visits: 100,
          crawlable: true,
          forward_query: true
        )
        expect(first_url.tags_array).to eq([ "tag1", "tag2" ])
        expect(first_url.meta_hash).to eq({ "description" => "Test URL" })
        expect(first_url.valid_since).to be_present
        expect(first_url.valid_until).to be_present

        second_url = user.short_urls.find_by(short_code: "def456")
        expect(second_url).to have_attributes(
          short_url: "https://s.test/def456",
          long_url: "https://example.com/another",
          domain: "s.test",
          title: nil,
          visit_count: 10,
          max_visits: nil,
          crawlable: false,
          forward_query: false
        )
        expect(second_url.tags_array).to eq([])
        expect(second_url.meta_hash).to eq({})
        expect(second_url.valid_since).to be_nil
        expect(second_url.valid_until).to be_nil
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
        expect { service.call }.to change(user.short_urls, :count).by(2)
      end
    end

    context "APIエラーの場合" do
      before do
        allow(mock_list_service).to receive(:call).and_raise(Shlink::Error, "API Error")
      end

      it "Shlink::Errorを再発生させること" do
        expect { service.call }.to raise_error(Shlink::Error, "API Error")
      end
    end

    context "不正な日付フォーマットの場合" do
      let(:invalid_date_data) do
        [
          {
            "shortCode" => "abc123",
            "shortUrl" => "https://s.test/abc123",
            "longUrl" => "https://example.com/test",
            "domain" => "s.test",
            "dateCreated" => "invalid-date"
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
        expect { service.call }.to change(user.short_urls, :count).by(1)

        short_url = user.short_urls.last
        expect(short_url.date_created).to be_within(1.minute).of(Time.current)
      end
    end
  end
end
