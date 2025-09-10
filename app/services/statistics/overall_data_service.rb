module Statistics
  class OverallDataService
    # キャッシュ有効期限: 1時間
    CACHE_EXPIRES = 1.hour

    def initialize(user, shlink_config: {})
      @user = user
      @shlink_config = shlink_config
    end

    # 全体統計データを取得（キャッシュ付き）
    def call(period = "30d")
      cache_key = "user_statistics:#{@user.id}:#{period}:#{Date.current}"

      Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRES) do
        generate_statistics_data(period)
      end
    end

    private

    def generate_statistics_data(period)
      {
        overall: generate_overall_data,
        daily: generate_daily_data(period),
        status: generate_status_data,
        monthly: generate_monthly_data
      }
    end

    # 全体サマリーデータ
    def generate_overall_data
      active_urls = @user.short_urls.active

      {
        total_urls: active_urls.count,
        total_visits: active_urls.sum(:visit_count),
        active_urls: active_urls.select(&:active?).count
      }
    end

    # 日別アクセス推移データ
    def generate_daily_data(period)
      days = parse_period_to_days(period)
      start_date = days.days.ago.beginning_of_day
      end_date = Time.current

      # ユーザーの全URLを取得
      all_urls = @user.short_urls.active

      # 各URLのアクセス統計を取得して日別に集計
      daily_visits_count = {}

      begin
        visits_service = Shlink::GetUrlVisitsService.new(**@shlink_config)

        all_urls.find_each do |url|
          begin
            visits_response = visits_service.call(
              url.short_code,
              start_date: start_date,
              end_date: end_date
            )

            next unless visits_response.is_a?(Hash)

            # 訪問データを抽出
            visits_data = if visits_response.key?("visits") && visits_response["visits"].is_a?(Hash) && visits_response["visits"].key?("data")
                            visits_response["visits"]["data"]
            elsif visits_response.key?("visits") && visits_response["visits"].is_a?(Array)
                            visits_response["visits"]
            elsif visits_response.key?("data") && visits_response["data"].is_a?(Array)
                            visits_response["data"]
            else
                            []
            end

            # 日別にカウント
            visits_data.each do |visit|
              next unless visit.is_a?(Hash) && visit["date"]

              begin
                visit_date = Date.parse(visit["date"]).strftime("%Y-%m-%d")
                daily_visits_count[visit_date] = (daily_visits_count[visit_date] || 0) + 1
              rescue Date::Error, ArgumentError => e
                Rails.logger.warn "Invalid date format in visit data: #{visit['date']}"
              end
            end
          rescue Shlink::Error => e
            Rails.logger.warn "Could not fetch visits for URL #{url.short_code}: #{e.message}"
            # 404 Not Found などのエラーは無視して続行
          end
        end
      rescue => e
        Rails.logger.error "Error fetching daily visits data: #{e.message}"
      end

      # 日付の配列を生成
      date_labels = (0...days).map { |i| (start_date + i.days).strftime("%m/%d") }

      # 各日のアクセス数を配列に変換（データがない日は0）
      values = date_labels.map.with_index do |label, index|
        date_key = (start_date + index.days).strftime("%Y-%m-%d")
        daily_visits_count[date_key] || 0
      end

      {
        labels: date_labels,
        values: values
      }
    end

    # URL状態分布データ
    def generate_status_data
      active_urls = @user.short_urls.active

      active_count = 0
      expired_count = 0
      limit_reached_count = 0

      active_urls.find_each do |url|
        if url.expired?
          expired_count += 1
        elsif url.visit_limit_reached?
          limit_reached_count += 1
        else
          active_count += 1
        end
      end

      {
        labels: [ "有効", "期限切れ", "制限到達" ],
        values: [ active_count, expired_count, limit_reached_count ]
      }
    end

    # 月別URL作成数データ
    def generate_monthly_data
      # 過去6ヶ月のデータを取得
      start_date = 6.months.ago.beginning_of_month

      # MySQLの日付関数を使用してグループ化
      monthly_stats = @user.short_urls.active
                           .where(date_created: start_date..Time.current)
                           .group("DATE_FORMAT(date_created, '%Y-%m')")
                           .count

      # 月のラベルを生成（過去6ヶ月）
      month_labels = (0...6).map { |i| (start_date + i.months).strftime("%Y-%m") }

      # 各月の作成数を配列に変換
      values = month_labels.map do |month_key|
        monthly_stats[month_key] || 0
      end

      {
        labels: month_labels.map { |label| Date.strptime(label, "%Y-%m").strftime("%m月") },
        values: values
      }
    end

    # 期間文字列を日数に変換
    def parse_period_to_days(period)
      case period
      when "7d"
        7
      when "30d"
        30
      when "90d"
        90
      when "365d"
        365
      else
        30 # デフォルト
      end
    end
  end
end
