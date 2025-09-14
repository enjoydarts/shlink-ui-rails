class Admin::DashboardController < Admin::AdminController
  def index
    @system_stats = Admin::SystemStatsService.new.call
    @server_monitor = Admin::ServerMonitorService.new.call
    @recent_errors = fetch_recent_errors
    @system_health = check_system_health
  end

  private

  # 最近のエラーログを取得（実装は後で詳細化）
  def fetch_recent_errors
    # TODO: ログファイルからエラーを取得する実装
    []
  end

  # システム健康状態をチェック
  def check_system_health
    {
      database: database_health,
      redis: redis_health,
      storage: storage_health
    }
  end

  def database_health
    # コネクションプールから接続を取得して実際にクエリを実行
    ActiveRecord::Base.connection_pool.with_connection do |connection|
      connection.execute("SELECT 1")
      true
    end
  rescue StandardError => e
    Rails.logger.error "Database health check failed: #{e.message}"
    false
  end

  def redis_health
    redis_url = ApplicationConfig.string("redis.url", Settings.redis&.url || "redis://redis:6379/0")
    redis = Redis.new(url: redis_url, connect_timeout: 1, read_timeout: 1, write_timeout: 1)
    redis.ping == "PONG"
  rescue Redis::ConnectionError, Redis::TimeoutError, Redis::CannotConnectError => e
    Rails.logger.error "Redis health check failed: #{e.message}"
    false
  rescue StandardError => e
    Rails.logger.error "Redis health check error: #{e.message}"
    false
  ensure
    redis&.close
  end

  def storage_health
    # ストレージ容量チェック
    available_space = `df -h / | tail -1 | awk '{print $5}' | sed 's/%//'`.to_i
    available_space < 90 # 使用率90%以下で健全
  rescue StandardError
    false
  end
end
