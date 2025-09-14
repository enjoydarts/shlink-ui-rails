require 'rails_helper'

RSpec.describe Statistics::IndividualUrlDataService, type: :service do
  let(:user) { create(:user) }
  let(:short_code) { 'abc123' }
  let(:service) { described_class.new(user, short_code) }

  before do
    # SystemSetting基本モック設定
    allow(SystemSetting).to receive(:get).and_call_original
    allow(SystemSetting).to receive(:get).with("shlink.base_url", nil).and_return("https://test.example.com")
    allow(SystemSetting).to receive(:get).with("shlink.api_key", nil).and_return("test-api-key")
    allow(SystemSetting).to receive(:get).with("performance.items_per_page", 20).and_return(20)
    allow(SystemSetting).to receive(:get).with('system.maintenance_mode', false).and_return(false)

    # ApplicationConfig基本モック設定
    allow(ApplicationConfig).to receive(:string).and_call_original
    allow(ApplicationConfig).to receive(:string).with('shlink.base_url', anything).and_return("https://test.example.com")
    allow(ApplicationConfig).to receive(:string).with('shlink.api_key', anything).and_return("test-api-key")
    allow(ApplicationConfig).to receive(:string).with('redis.url', anything).and_return("redis://redis:6379/0")
    allow(ApplicationConfig).to receive(:number).and_call_original
    allow(ApplicationConfig).to receive(:number).with('shlink.timeout', anything).and_return(30)
    allow(ApplicationConfig).to receive(:number).with('redis.timeout', anything).and_return(5)

    # WebMockスタブを追加
    stub_request(:get, %r{https://test\.example\.com/rest/v3/short-urls/.+/visits})
      .to_return(
        status: 200,
        body: { visits: { data: [] } }.to_json,
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
      let(:error_service) { described_class.new(user, short_code) }

      before do
        # Shlink::GetUrlVisitsServiceを直接モックしてエラーを発生させる
        visits_service = instance_double(Shlink::GetUrlVisitsService)
        allow(visits_service).to receive(:call).and_raise(Shlink::Error.new("API error"))
        allow(Shlink::GetUrlVisitsService).to receive(:new).and_return(visits_service)
      end

      it 'エラーをハンドリングして空のデータを返すこと' do
        result = error_service.call('7d')
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
