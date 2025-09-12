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
    ActiveRecord::Base.connection.active?
  rescue StandardError
    false
  end

  def redis_health
    # Redis接続確認（使用している場合）
    true # TODO: Redis使用時は実装
  end

  def storage_health
    # ストレージ容量チェック
    available_space = `df -h / | tail -1 | awk '{print $5}' | sed 's/%//'`.to_i
    available_space < 90 # 使用率90%以下で健全
  rescue StandardError
    false
  end
end
