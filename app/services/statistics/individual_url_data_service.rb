module Statistics
  class IndividualUrlDataService
    CACHE_EXPIRES = 30.minutes

    def initialize(user, short_code, shlink_config: {})
      @user = user
      @short_code = short_code
      @shlink_config = shlink_config
    end

    def call(period = "30d")
      cache_key = "individual_url_statistics:#{@user.id}:#{@short_code}:#{period}:#{Date.current}"
      Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRES) do
        generate_statistics_data(period)
      end
    end

    private

    def generate_statistics_data(period)
      start_date, end_date = calculate_date_range(period)

      begin
        # Shlink APIから個別URL訪問データを取得
        visits_service = Shlink::GetUrlVisitsService.new(**@shlink_config)
        visits_response = visits_service.call(
          @short_code,
          start_date: start_date,
          end_date: end_date
        )

        # デバッグ用ログ
        Rails.logger.info "Shlink API response class: #{visits_response.class}"
        Rails.logger.info "Shlink API response: #{visits_response.inspect}"

        # レスポンスがHashでない場合はエラー
        unless visits_response.is_a?(Hash)
          Rails.logger.error "Invalid Shlink API response format: #{visits_response.class} - #{visits_response.inspect}"
          return generate_empty_data
        end

        # visits.dataの構造でアクセス、フォールバックでvisitsまたは空配列
        visits_data = if visits_response.key?("visits") && visits_response["visits"].is_a?(Hash) && visits_response["visits"].key?("data")
                        visits_response["visits"]["data"]
        elsif visits_response.key?("visits") && visits_response["visits"].is_a?(Array)
                        visits_response["visits"]
        elsif visits_response.key?("data") && visits_response["data"].is_a?(Array)
                        visits_response["data"]
        else
                        Rails.logger.warn "Could not extract visits data from response: #{visits_response.keys}"
                        []
        end

        Rails.logger.info "Extracted visits_data count: #{visits_data.length}"

        {
          daily_visits: generate_daily_visits_data(visits_data, start_date, end_date),
          hourly_visits: generate_hourly_visits_data(visits_data),
          browser_stats: generate_browser_stats(visits_data),
          country_stats: generate_country_stats(visits_data),
          referer_stats: generate_referer_stats(visits_data),
          total_visits: visits_data.length,
          unique_visitors: count_unique_visitors(visits_data),
          url_info: get_url_info
        }
      rescue Shlink::Error => e
        Rails.logger.error "Individual URL statistics error: #{e.message}"
        generate_empty_data
      end
    end

    def calculate_date_range(period)
      case period
      when "7d"
        [ 7.days.ago, Time.current ]
      when "30d"
        [ 30.days.ago, Time.current ]
      when "90d"
        [ 90.days.ago, Time.current ]
      when "365d"
        [ 365.days.ago, Time.current ]
      else
        [ 30.days.ago, Time.current ]
      end
    end

    def generate_daily_visits_data(visits_data, start_date, end_date)
      return { labels: [], values: [] } unless visits_data.is_a?(Array)

      # 日別グループ化
      daily_counts = visits_data.group_by do |visit|
        next "unknown" unless visit.is_a?(Hash) && visit["date"]

        begin
          Date.parse(visit["date"]).strftime("%Y-%m-%d")
        rescue Date::Error, ArgumentError => e
          Rails.logger.warn "Invalid date format in visit data: #{visit['date']}"
          "unknown"
        end
      end.transform_values(&:count)

      # 'unknown'キーを除去
      daily_counts.delete("unknown")

      # 期間内の全ての日付を生成
      date_range = (start_date.to_date..end_date.to_date)
      labels = date_range.map { |date| date.strftime("%m/%d") }
      values = date_range.map { |date| daily_counts[date.strftime("%Y-%m-%d")] || 0 }

      {
        labels: labels,
        values: values
      }
    end

    def generate_hourly_visits_data(visits_data)
      return { labels: [], values: [] } unless visits_data.is_a?(Array)

      hourly_counts = visits_data.group_by do |visit|
        next -1 unless visit.is_a?(Hash) && visit["date"]

        begin
          Time.parse(visit["date"]).hour
        rescue Date::Error, ArgumentError => e
          Rails.logger.warn "Invalid date format in hourly visit data: #{visit['date']}"
          -1
        end
      end.transform_values(&:count)

      # 無効なキーを除去
      hourly_counts.delete(-1)

      labels = (0..23).map { |h| "#{h}:00" }
      values = (0..23).map { |h| hourly_counts[h] || 0 }

      {
        labels: labels,
        values: values
      }
    end

    def generate_browser_stats(visits_data)
      return { labels: [], values: [] } unless visits_data.is_a?(Array)

      browser_counts = visits_data.group_by do |visit|
        next "Unknown" unless visit.is_a?(Hash)

        user_agent = visit["userAgent"]
        if user_agent.is_a?(Hash)
          user_agent["browser"] || "Unknown"
        elsif user_agent.is_a?(String)
          # User-Agentが文字列の場合は簡易的にブラウザを判定
          case user_agent
          when /Chrome/
            "Chrome"
          when /Firefox/
            "Firefox"
          when /Safari/
            "Safari"
          when /Edge/
            "Edge"
          else
            "Other"
          end
        else
          "Unknown"
        end
      end.transform_values(&:count)

      {
        labels: browser_counts.keys,
        values: browser_counts.values
      }
    end

    def generate_country_stats(visits_data)
      return { labels: [], values: [] } unless visits_data.is_a?(Array)

      country_counts = visits_data.group_by do |visit|
        next "Unknown" unless visit.is_a?(Hash)

        visit_location = visit["visitLocation"]
        if visit_location.is_a?(Hash)
          visit_location["countryName"] || "Unknown"
        else
          "Unknown"
        end
      end.transform_values(&:count)

      {
        labels: country_counts.keys.first(10), # Top 10
        values: country_counts.values.first(10)
      }
    end

    def generate_referer_stats(visits_data)
      return { labels: [], values: [] } unless visits_data.is_a?(Array)

      referer_counts = visits_data.group_by do |visit|
        next "Unknown" unless visit.is_a?(Hash)
        referer = visit["referer"]
        next "Direct" if referer.blank?

        begin
          URI.parse(referer).host
        rescue URI::InvalidURIError
          "Unknown"
        end
      end.transform_values(&:count)

      {
        labels: referer_counts.keys.first(10), # Top 10
        values: referer_counts.values.first(10)
      }
    end

    def count_unique_visitors(visits_data)
      return 0 unless visits_data.is_a?(Array)

      # IPアドレスベースの簡易的なユニーク訪問者数
      visits_data.filter_map do |visit|
        next unless visit.is_a?(Hash)

        visit_location = visit["visitLocation"]
        if visit_location.is_a?(Hash)
          visit_location["ipAddress"]
        else
          nil
        end
      end.uniq.count
    end

    def get_url_info
      # URLの基本情報を取得（既存のShortUrlモデルから）
      url = @user.short_urls.find_by(short_code: @short_code)
      return nil unless url

      {
        short_code: url.short_code,
        long_url: url.long_url,
        title: url.title,
        tags: url.tags_array || [],
        date_created: url.date_created
      }
    end

    def generate_empty_data
      {
        daily_visits: { labels: [], values: [] },
        hourly_visits: { labels: [], values: [] },
        browser_stats: { labels: [], values: [] },
        country_stats: { labels: [], values: [] },
        referer_stats: { labels: [], values: [] },
        total_visits: 0,
        unique_visitors: 0,
        url_info: nil
      }
    end
  end
end
