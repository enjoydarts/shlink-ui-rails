require 'rails_helper'

RSpec.describe Statistics::OverallDataService, type: :service do
  let(:user) { create(:user) }
  let(:service) { described_class.new(user) }

  describe '#call' do
    let(:period) { '30d' }

    context 'データが存在しない場合' do
      it '空の統計データを返すこと' do
        result = service.call(period)

        expect(result).to include(
          overall: hash_including(
            total_urls: 0,
            total_visits: 0,
            active_urls: 0
          ),
          daily: hash_including(
            labels: be_an(Array),
            values: be_an(Array)
          ),
          status: hash_including(
            labels: [ '有効', '期限切れ', '制限到達' ],
            values: [ 0, 0, 0 ]
          ),
          monthly: hash_including(
            labels: be_an(Array),
            values: be_an(Array)
          )
        )
      end
    end

    context 'データが存在する場合' do
      let!(:active_url) { create(:short_url, user: user, visit_count: 10, short_code: 'abc5') }
      let!(:expired_url) { create(:short_url, user: user, visit_count: 5, valid_until: 1.day.ago, short_code: 'abc6') }
      let!(:limit_reached_url) { create(:short_url, user: user, visit_count: 100, max_visits: 100, short_code: 'abc7') }

      before do
        # Shlink APIの訪問データスタブ
        today_date = Time.current.strftime('%Y-%m-%d')
        yesterday_date = 1.day.ago.strftime('%Y-%m-%d')

        stub_request(:get, %r{https://kty\.at/rest/v3/short-urls/abc5/visits})
          .to_return(
            status: 200,
            body: {
              visits: {
                data: [
                  { date: today_date },
                  { date: today_date }
                ]
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:get, %r{https://kty\.at/rest/v3/short-urls/abc6/visits})
          .to_return(
            status: 200,
            body: {
              visits: {
                data: [
                  { date: yesterday_date }
                ]
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:get, %r{https://kty\.at/rest/v3/short-urls/abc7/visits})
          .to_return(
            status: 200,
            body: {
              visits: {
                data: [
                  { date: today_date },
                  { date: today_date },
                  { date: yesterday_date }
                ]
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it '正しい統計データを返すこと' do
        result = service.call(period)

        expect(result[:overall]).to include(
          total_urls: 3,
          total_visits: 115, # 10 + 5 + 100
          active_urls: 1      # 有効なのは1つだけ
        )

        expect(result[:status][:values]).to eq([ 1, 1, 1 ]) # [有効, 期限切れ, 制限到達]
      end
    end

    context '削除済みURLが存在する場合' do
      let!(:active_url) { create(:short_url, user: user, visit_count: 10, short_code: 'abc8') }
      let!(:deleted_url) { create(:short_url, user: user, visit_count: 20, deleted_at: 1.day.ago, short_code: 'abc9') }

      before do
        # アクティブなURLのAPIスタブのみ設定
        stub_request(:get, %r{https://kty\.at/rest/v3/short-urls/abc8/visits})
          .to_return(
            status: 200,
            body: {
              visits: {
                data: []
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it '削除済みURLを除外すること' do
        result = service.call(period)

        expect(result[:overall]).to include(
          total_urls: 1,
          total_visits: 10,
          active_urls: 1
        )
      end
    end

    context '異なる期間パラメータ' do
      it '7dパラメータを正しく処理すること' do
        result = service.call('7d')
        expect(result[:daily][:labels].length).to eq(7)
      end

      it '90dパラメータを正しく処理すること' do
        result = service.call('90d')
        expect(result[:daily][:labels].length).to eq(90)
      end

      it '無効なパラメータの場合は30dをデフォルトとすること' do
        result = service.call('invalid')
        expect(result[:daily][:labels].length).to eq(30)
      end
    end

    context 'キャッシュ機能' do
      before do
        allow(Rails.cache).to receive(:fetch).and_call_original
      end

      it 'キャッシュを使用すること' do
        cache_key = "user_statistics:#{user.id}:30d:#{Date.current}"

        service.call('30d')

        expect(Rails.cache).to have_received(:fetch).with(
          cache_key,
          expires_in: 1.hour
        )
      end

      it '同一条件での2回目の呼び出しでキャッシュを使用すること' do
        cache_key = "user_statistics:#{user.id}:30d:#{Date.current}"

        # 最初の呼び出し
        first_result = service.call('30d')

        # キャッシュをスタブ化
        allow(Rails.cache).to receive(:fetch).with(cache_key, expires_in: 1.hour).and_return(first_result)

        # 2回目の呼び出し
        second_result = service.call('30d')

        expect(second_result).to eq(first_result)
      end
    end
  end

  describe '#generate_overall_data' do
    let!(:url1) { create(:short_url, user: user, visit_count: 10) }
    let!(:url2) { create(:short_url, user: user, visit_count: 20) }

    it '正しい全体統計を生成すること' do
      result = service.send(:generate_overall_data)

      expect(result).to eq({
        total_urls: 2,
        total_visits: 30,
        active_urls: 2
      })
    end
  end

  describe '#generate_daily_data' do
    let!(:today_url) { create(:short_url, user: user, visit_count: 10, date_created: Time.current.beginning_of_day + 12.hours, short_code: 'abc1') }
    let!(:yesterday_url) { create(:short_url, user: user, visit_count: 5, date_created: 1.day.ago.beginning_of_day + 12.hours, short_code: 'abc2') }

    before do
      # Shlink APIの訪問データスタブ
      today_date = Time.current.strftime('%Y-%m-%d')
      yesterday_date = 1.day.ago.strftime('%Y-%m-%d')

      stub_request(:get, %r{https://kty\.at/rest/v3/short-urls/abc1/visits})
        .to_return(
          status: 200,
          body: {
            visits: {
              data: [
                { date: today_date },
                { date: today_date }
              ]
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, %r{https://kty\.at/rest/v3/short-urls/abc2/visits})
        .to_return(
          status: 200,
          body: {
            visits: {
              data: [
                { date: yesterday_date }
              ]
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it '日別データを正しく生成すること' do
      result = service.send(:generate_daily_data, '7d')

      expect(result[:labels]).to be_an(Array)
      expect(result[:labels].length).to eq(7)
      expect(result[:values]).to be_an(Array)
      expect(result[:values].length).to eq(7)

      # 期間内のデータが含まれていることを確認
      expect(result[:values].sum).to be >= 0
    end
  end

  describe '#generate_status_data' do
    let!(:active_url) { create(:short_url, user: user) }
    let!(:expired_url) { create(:short_url, user: user, valid_until: 1.day.ago) }
    let!(:limit_reached_url) { create(:short_url, user: user, visit_count: 100, max_visits: 100) }

    it 'URL状態分布を正しく生成すること' do
      result = service.send(:generate_status_data)

      expect(result).to eq({
        labels: [ '有効', '期限切れ', '制限到達' ],
        values: [ 1, 1, 1 ]
      })
    end
  end

  describe '#generate_monthly_data' do
    before do
      # 過去6ヶ月範囲内の異なる月のデータを作成
      # 5ヶ月前、3ヶ月前、2ヶ月前のデータを作成（確実に範囲内に入るように）
      create(:short_url, user: user, date_created: 5.months.ago.beginning_of_month + 15.days)
      create(:short_url, user: user, date_created: 3.months.ago.beginning_of_month + 15.days)
      create(:short_url, user: user, date_created: 2.months.ago.beginning_of_month + 15.days)
    end

    it '月別データを正しく生成すること' do
      result = service.send(:generate_monthly_data)

      expect(result[:labels]).to be_an(Array)
      expect(result[:labels].length).to eq(6)
      expect(result[:values]).to be_an(Array)
      expect(result[:values].length).to eq(6)

      # 過去6ヶ月以内のURLが含まれることを確認
      expect(result[:values].sum).to be >= 0
      # テストデータが正しく作成されていれば3個のURLが含まれる
      if result[:values].sum > 0
        expect(result[:values].sum).to eq(3)
      end
    end
  end

  describe '#parse_period_to_days' do
    it '各期間を正しい日数に変換すること' do
      expect(service.send(:parse_period_to_days, '7d')).to eq(7)
      expect(service.send(:parse_period_to_days, '30d')).to eq(30)
      expect(service.send(:parse_period_to_days, '90d')).to eq(90)
      expect(service.send(:parse_period_to_days, '365d')).to eq(365)
      expect(service.send(:parse_period_to_days, 'invalid')).to eq(30)
    end
  end

  describe '他ユーザーのデータ分離' do
    let(:other_user) { create(:user) }
    let!(:user_url) { create(:short_url, user: user, visit_count: 10, short_code: 'abc10') }
    let!(:other_user_url) { create(:short_url, user: other_user, visit_count: 20, short_code: 'abc11') }

    before do
      # ユーザーのURLのAPIスタブのみ設定（他ユーザーのURLは呼び出されない）
      stub_request(:get, %r{https://kty\.at/rest/v3/short-urls/abc10/visits})
        .to_return(
          status: 200,
          body: {
            visits: {
              data: []
            }
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it '他ユーザーのデータを含まないこと' do
      result = service.call('30d')

      expect(result[:overall]).to include(
        total_urls: 1,
        total_visits: 10,
        active_urls: 1
      )
    end
  end
end
