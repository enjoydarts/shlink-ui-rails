require 'rails_helper'

RSpec.describe Shlink::GetUrlVisitsService do
  let(:service) { described_class.new }
  let(:short_code) { 'abc123' }

  before do
    allow(SystemSetting).to receive(:get).with("performance.items_per_page", 20).and_return(20)
    allow(service).to receive(:conn).and_return(faraday_double)
    allow(service).to receive(:api_headers).and_return({ 'X-Api-Key' => 'test-key' })
  end

  let(:faraday_double) { double('Faraday::Connection') }
  let(:success_response) do
    double('Faraday::Response',
      status: 200,
      body: {
        visits: {
          pagination: { currentPage: 1, pagesCount: 1, totalItems: 3 },
          data: [
            { referer: 'https://example.com', date: '2023-10-01T10:00:00+00:00', userAgent: 'Mozilla/5.0...' },
            { referer: 'https://google.com', date: '2023-10-01T11:00:00+00:00', userAgent: 'Chrome...' },
            { referer: '', date: '2023-10-01T12:00:00+00:00', userAgent: 'Safari...' }
          ]
        }
      }.to_json
    )
  end

  describe '#call' do
    context '正常なレスポンスの場合' do
      before do
        allow(faraday_double).to receive(:get).and_return(success_response)
        allow(service).to receive(:handle_response).with(success_response).and_return(success_response)
      end

      it '指定された短縮URLの訪問統計を正常に取得すること' do
        result = service.call(short_code)

        expect(faraday_double).to have_received(:get).with(
          "/rest/v3/short-urls/#{short_code}/visits",
          { page: 1, itemsPerPage: 200 },
          { 'X-Api-Key' => 'test-key' }
        )
        expect(result).to eq(success_response)
      end

      it 'デフォルトパラメータで呼び出されること' do
        service.call(short_code)

        expect(faraday_double).to have_received(:get).with(
          "/rest/v3/short-urls/#{short_code}/visits",
          { page: 1, itemsPerPage: 200 },
          { 'X-Api-Key' => 'test-key' }
        )
      end
    end

    context 'パラメータを指定した場合' do
      before do
        allow(faraday_double).to receive(:get).and_return(success_response)
        allow(service).to receive(:handle_response).with(success_response).and_return(success_response)
      end

      it '開始日・終了日・ページ・アイテム数を正しく設定すること' do
        start_date = Date.new(2023, 10, 1)
        end_date = Date.new(2023, 10, 31)

        service.call(short_code, start_date: start_date, end_date: end_date, page: 3, items_per_page: 25)

        expect(faraday_double).to have_received(:get).with(
          "/rest/v3/short-urls/#{short_code}/visits",
          {
            page: 3,
            itemsPerPage: 25,
            startDate: "2023-10-01",
            endDate: "2023-10-31"
          },
          { 'X-Api-Key' => 'test-key' }
        )
      end
    end

    context 'items_per_pageがnilの場合' do
      before do
        allow(faraday_double).to receive(:get).and_return(success_response)
        allow(service).to receive(:handle_response).with(success_response).and_return(success_response)
      end

      it 'SystemSettingからデフォルト値を取得すること' do
        service.call(short_code, items_per_page: nil)

        expect(SystemSetting).to have_received(:get).with("performance.items_per_page", 20)
        expect(faraday_double).to have_received(:get).with(
          "/rest/v3/short-urls/#{short_code}/visits",
          { page: 1, itemsPerPage: 200 },
          { 'X-Api-Key' => 'test-key' }
        )
      end
    end
  end

  describe '#call!' do
    context '正常なレスポンスの場合' do
      before do
        allow(service).to receive(:call).and_return(success_response)
      end

      it 'callメソッドを呼び出すこと' do
        start_date = Date.new(2023, 10, 1)
        end_date = Date.new(2023, 10, 31)

        result = service.call!(short_code, start_date: start_date, end_date: end_date, page: 2, items_per_page: 30)

        expect(service).to have_received(:call).with(
          short_code,
          start_date: start_date,
          end_date: end_date,
          page: 2,
          items_per_page: 30
        )
        expect(result).to eq(success_response)
      end
    end

    context 'エラーが発生した場合' do
      let(:error) { StandardError.new('Network Error') }

      before do
        allow(service).to receive(:call).and_raise(error)
      end

      it 'エラーを再発生させること' do
        expect {
          service.call!(short_code)
        }.to raise_error(StandardError, 'Network Error')
      end
    end
  end

  describe '#build_params (private method)' do
    it 'パラメータを正しく構築すること' do
      start_date = Date.new(2023, 9, 15)
      end_date = Date.new(2023, 9, 30)

      params = service.send(:build_params, start_date, end_date, 5, 15)

      expect(params).to eq({
        page: 5,
        itemsPerPage: 15,
        startDate: "2023-09-15",
        endDate: "2023-09-30"
      })
    end

    it '日付がnilの場合は含めないこと' do
      params = service.send(:build_params, nil, nil, 1, 100)

      expect(params).to eq({
        page: 1,
        itemsPerPage: 100
      })
    end

    it '開始日のみ指定した場合' do
      start_date = Date.new(2023, 8, 1)

      params = service.send(:build_params, start_date, nil, 2, 50)

      expect(params).to eq({
        page: 2,
        itemsPerPage: 50,
        startDate: "2023-08-01"
      })
    end

    it '終了日のみ指定した場合' do
      end_date = Date.new(2023, 8, 31)

      params = service.send(:build_params, nil, end_date, 1, 40)

      expect(params).to eq({
        page: 1,
        itemsPerPage: 40,
        endDate: "2023-08-31"
      })
    end
  end
end
