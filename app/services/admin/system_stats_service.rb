class Admin::SystemStatsService
  def call
    {
      users: user_statistics,
      short_urls: short_url_statistics,
      system: system_statistics
    }
  end

  private

  def user_statistics
    {
      total: User.count,
      admin: User.where(role: "admin").count,
      normal: User.where(role: "normal_user").count,
      active_today: User.where("current_sign_in_at >= ?", 24.hours.ago).count,
      active_this_week: User.where("current_sign_in_at >= ?", 1.week.ago).count,
      registered_today: User.where("created_at >= ?", 24.hours.ago).count,
      registered_this_week: User.where("created_at >= ?", 1.week.ago).count,
      registered_this_month: User.where("created_at >= ?", 1.month.ago).count
    }
  end

  def short_url_statistics
    {
      total: ShortUrl.count,
      created_today: ShortUrl.where("created_at >= ?", 24.hours.ago).count,
      created_this_week: ShortUrl.where("created_at >= ?", 1.week.ago).count,
      created_this_month: ShortUrl.where("created_at >= ?", 1.month.ago).count,
      total_visits: ShortUrl.sum(:visit_count),
      visits_today: calculate_visits_today,
      visits_this_week: calculate_visits_this_week,
      most_popular: most_popular_short_urls,
      recent_created: recent_short_urls
    }
  end

  def system_statistics
    {
      uptime: system_uptime,
      version: rails_version_info,
      database: database_statistics,
      background_jobs: background_job_statistics
    }
  end

  def calculate_visits_today
    # TODO: 実際の訪問統計を計算（Shlink APIまたはローカル統計から）
    0
  end

  def calculate_visits_this_week
    # TODO: 実際の訪問統計を計算（Shlink APIまたはローカル統計から）
    0
  end

  def most_popular_short_urls(limit = 5)
    ShortUrl.order(visit_count: :desc)
            .limit(limit)
            .pluck(:short_code, :short_url, :long_url, :visit_count)
            .map do |code, short_url, long_url, visits|
              {
                short_code: code,
                short_url: short_url,
                long_url: truncate_url(long_url),
                visit_count: visits
              }
            end
  end

  def recent_short_urls(limit = 5)
    ShortUrl.includes(:user)
            .order(created_at: :desc)
            .limit(limit)
            .map do |short_url|
              {
                short_code: short_url.short_code,
                short_url: short_url.short_url,
                long_url: truncate_url(short_url.long_url),
                user_name: short_url.user.display_name,
                created_at: short_url.created_at
              }
            end
  end

  def system_uptime
    uptime_seconds = File.read("/proc/uptime").split.first.to_f
    {
      seconds: uptime_seconds.to_i,
      formatted: format_uptime(uptime_seconds)
    }
  rescue StandardError
    { seconds: 0, formatted: "不明" }
  end

  def rails_version_info
    {
      rails: Rails.version,
      ruby: RUBY_VERSION,
      environment: Rails.env
    }
  end

  def database_statistics
    {
      adapter: ActiveRecord::Base.connection.adapter_name,
      version: database_version,
      size: database_size
    }
  rescue StandardError => e
    {
      adapter: "Unknown",
      version: "Unknown",
      size: "Unknown",
      error: e.message
    }
  end

  def background_job_statistics
    # SolidQueueの統計情報を取得
    {
      pending: SolidQueue::Job.where(finished_at: nil, scheduled_at: nil).count,
      scheduled: SolidQueue::Job.where(finished_at: nil).where.not(scheduled_at: nil).count,
      completed: SolidQueue::Job.where.not(finished_at: nil).count,
      failed: SolidQueue::FailedExecution.count
    }
  rescue StandardError
    {
      pending: 0,
      scheduled: 0,
      completed: 0,
      failed: 0
    }
  end

  def database_version
    case ActiveRecord::Base.connection.adapter_name.downcase
    when "mysql2", "mysql"
      ActiveRecord::Base.connection.execute("SELECT VERSION()").first.first
    when "postgresql"
      ActiveRecord::Base.connection.execute("SELECT version()").first["version"]
    else
      "Unknown"
    end
  end

  def database_size
    case ActiveRecord::Base.connection.adapter_name.downcase
    when "mysql2", "mysql"
      db_name = ActiveRecord::Base.connection.current_database
      result = ActiveRecord::Base.connection.execute(
        "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) AS size_mb
         FROM information_schema.tables
         WHERE table_schema = '#{db_name}'"
      ).first.first
      "#{result} MB"
    else
      "Unknown"
    end
  rescue StandardError
    "Unknown"
  end

  def format_uptime(seconds)
    days = (seconds / 86400).to_i
    hours = ((seconds % 86400) / 3600).to_i
    minutes = ((seconds % 3600) / 60).to_i

    if days > 0
      "#{days}日 #{hours}時間 #{minutes}分"
    elsif hours > 0
      "#{hours}時間 #{minutes}分"
    else
      "#{minutes}分"
    end
  end

  def truncate_url(url, length = 50)
    return url if url.length <= length

    "#{url[0..length - 4]}..."
  end
end
