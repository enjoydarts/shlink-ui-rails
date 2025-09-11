require 'rails_helper'

RSpec.describe Statistics::IndividualUrlDataService, type: :service do
  let(:user) { create(:user) }
  let(:short_code) { 'abc123' }
  let(:service) { described_class.new(user, short_code) }

  before do
    # Mock Shlink API responses
    stub_request(:get, %r{https://test\.example\.com/rest/v3/short-urls/abc123/visits})
      .to_return(
        status: 200,
        body: {
          visits: {
            data: [
              {
                date: '2025-09-09',
                userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                referer: 'https://google.com',
                country: 'Japan'
              },
              {
                date: '2025-09-08',
                userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
                referer: '',
                country: 'Japan'
              }
            ]
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  describe '#call' do
    it '統計データを正しく返すこと' do
      result = service.call('7d')

      expect(result).to include(
        :total_visits,
        :unique_visitors,
        :daily_visits,
        :hourly_visits,
        :browser_stats,
        :country_stats,
        :referer_stats
      )
    end

    it '日別アクセス統計を含むこと' do
      result = service.call('7d')

      expect(result[:daily_visits]).to include(:labels, :values)
      expect(result[:daily_visits][:labels]).to be_an(Array)
      expect(result[:daily_visits][:values]).to be_an(Array)
    end

    it '時間帯別統計を含むこと' do
      result = service.call('7d')

      expect(result[:hourly_visits]).to include(:labels, :values)
      expect(result[:hourly_visits][:labels].length).to eq(24)
    end

    it 'ブラウザ統計を含むこと' do
      result = service.call('7d')

      expect(result[:browser_stats]).to include(:labels, :values)
      expect(result[:browser_stats][:labels]).to be_an(Array)
    end

    it '国別統計を含むこと' do
      result = service.call('7d')

      expect(result[:country_stats]).to include(:labels, :values)
      expect(result[:country_stats][:labels]).to be_an(Array)
    end

    it '参照元統計を含むこと' do
      result = service.call('7d')

      expect(result[:referer_stats]).to include(:labels, :values)
      expect(result[:referer_stats][:labels]).to be_an(Array)
    end

    context 'APIエラーの場合' do
      before do
        stub_request(:get, %r{https://test\.example\.com/rest/v3/short-urls/abc123/visits})
          .to_return(status: 404, body: { error: 'Not found' }.to_json)
      end

      it 'エラーをハンドリングして空のデータを返すこと' do
        result = service.call('7d')
        expect(result[:total_visits]).to eq(0)
        expect(result[:unique_visitors]).to eq(0)
        expect(result[:daily_visits][:labels]).to be_empty
        expect(result[:daily_visits][:values]).to be_empty
      end
    end

    context '異なる期間パラメータ' do
      it '7dパラメータを正しく処理すること' do
        result = service.call('7d')
        expect(result[:daily_visits][:labels].length).to be >= 7
      end

      it '30dパラメータを正しく処理すること' do
        result = service.call('30d')
        expect(result[:daily_visits][:labels].length).to be >= 30
      end
    end
  end
end
