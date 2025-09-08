require 'rails_helper'

RSpec.describe Shlink::ListShortUrlsService do
  let(:service) { described_class.new }
  let(:base_url) { "https://s.test" }
  let(:api_key) { "test_api_key" }

  before do
    allow(Settings.shlink).to receive(:base_url).and_return(base_url)
    allow(Settings.shlink).to receive(:api_key).and_return(api_key)
  end

  describe "#call" do
    let(:response_body) do
      {
        "shortUrls" => {
          "data" => [
            {
              "shortCode" => "abc123",
              "shortUrl" => "https://s.test/abc123",
              "longUrl" => "https://example.com/test",
              "domain" => "s.test",
              "title" => "Test Page",
              "tags" => [ "tag1", "tag2" ],
              "meta" => { "description" => "Test URL" },
              "visitsSummary" => { "total" => 5 },
              "dateCreated" => "2023-01-01T00:00:00Z"
            }
          ],
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

    context "成功した場合" do
      before do
        stub_request(:get, /#{Regexp.escape(base_url)}\/rest\/v3\/short-urls/)
          .with(headers: { "X-Api-Key" => api_key })
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "短縮URL一覧を返すこと" do
        result = service.call

        expect(result).to eq(response_body)
      end
    end

    context "パラメータありの場合" do
      let(:params) do
        {
          page: 2,
          items_per_page: 50,
          search_term: "test",
          tags: [ "tag1" ],
          order_by: "dateCreated-DESC",
          start_date: Date.new(2023, 1, 1),
          end_date: Date.new(2023, 12, 31)
        }
      end

      before do
        stub_request(:get, /#{Regexp.escape(base_url)}\/rest\/v3\/short-urls/)
          .with(headers: { "X-Api-Key" => api_key })
          .to_return(
            status: 200,
            body: response_body.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "パラメータを正しく送信すること" do
        result = service.call(**params)

        expect(result).to eq(response_body)
      end
    end

    context "APIエラーの場合" do
      before do
        stub_request(:get, /#{Regexp.escape(base_url)}\/rest\/v3\/short-urls/)
          .with(headers: { "X-Api-Key" => api_key })
          .to_return(
            status: 400,
            body: { "title" => "Bad Request", "detail" => "Invalid parameters" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "Shlink::Errorを発生させること" do
        expect { service.call }.to raise_error(Shlink::Error, /Invalid parameters/)
      end
    end
  end

  describe "#call!" do
    context "成功した場合" do
      before do
        stub_request(:get, /#{Regexp.escape(base_url)}\/rest\/v3\/short-urls/)
          .with(headers: { "X-Api-Key" => api_key })
          .to_return(
            status: 200,
            body: { "shortUrls" => { "data" => [] } }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "例外を発生させないこと" do
        expect { service.call! }.not_to raise_error
      end
    end

    context "エラーの場合" do
      before do
        stub_request(:get, /#{Regexp.escape(base_url)}\/rest\/v3\/short-urls/)
          .with(headers: { "X-Api-Key" => api_key })
          .to_return(status: 500)
      end

      it "例外を再発生させること" do
        expect { service.call! }.to raise_error(Shlink::Error)
      end
    end
  end
end
