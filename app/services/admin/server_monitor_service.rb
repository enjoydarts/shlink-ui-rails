class Admin::ServerMonitorService
  def call
    {
      system: system_resources,
      performance: performance_metrics,
      health: health_checks
    }
  end

  private

  def system_resources
    {
      memory: memory_usage,
      disk: disk_usage,
      cpu: cpu_usage,
      load_average: load_average
    }
  end

  def performance_metrics
    {
      response_time: average_response_time,
      active_connections: active_connections,
      requests_per_minute: requests_per_minute
    }
  end

  def health_checks
    {
      database: database_health,
      external_apis: external_api_health,
      background_jobs: background_job_health
    }
  end

  def memory_usage
    return { error: "メモリ情報取得不可" } unless File.exist?("/proc/meminfo")

    meminfo = File.read("/proc/meminfo")
    total_kb = meminfo.match(/MemTotal:\s+(\d+)/)[1].to_i
    available_kb = meminfo.match(/MemAvailable:\s+(\d+)/)[1].to_i

    used_kb = total_kb - available_kb
    usage_percent = (used_kb.to_f / total_kb * 100).round(1)

    {
      total: format_bytes(total_kb * 1024),
      used: format_bytes(used_kb * 1024),
      available: format_bytes(available_kb * 1024),
      usage_percent: usage_percent,
      status: memory_status(usage_percent)
    }
  rescue StandardError => e
    { error: "メモリ情報取得エラー: #{e.message}" }
  end

  def disk_usage
    return { error: "ディスク情報取得不可" } unless system_command_available?("df")

    df_output = `df -h / | tail -1`.strip.split
    total = df_output[1]
    used = df_output[2]
    available = df_output[3]
    usage_percent = df_output[4].gsub("%", "").to_i

    {
      total: total,
      used: used,
      available: available,
      usage_percent: usage_percent,
      status: disk_status(usage_percent)
    }
  rescue StandardError => e
    { error: "ディスク情報取得エラー: #{e.message}" }
  end

  def cpu_usage
    return { error: "CPU情報取得不可" } unless File.exist?("/proc/loadavg")

    loadavg = File.read("/proc/loadavg").split
    load_1min = loadavg[0].to_f
    load_5min = loadavg[1].to_f
    load_15min = loadavg[2].to_f

    cpu_cores = cpu_core_count
    cpu_usage_percent = (load_1min / cpu_cores * 100).round(1)

    {
      load_1min: load_1min,
      load_5min: load_5min,
      load_15min: load_15min,
      cores: cpu_cores,
      usage_percent: cpu_usage_percent,
      status: cpu_status(cpu_usage_percent)
    }
  rescue StandardError => e
    { error: "CPU情報取得エラー: #{e.message}" }
  end

  def load_average
    return { error: "ロードアベレージ取得不可" } unless File.exist?("/proc/loadavg")

    loadavg = File.read("/proc/loadavg").strip
    {
      raw: loadavg,
      values: loadavg.split[0..2].map(&:to_f)
    }
  rescue StandardError => e
    { error: "ロードアベレージ取得エラー: #{e.message}" }
  end

  def average_response_time
    # TODO: 実際のレスポンス時間を計測（APMツールまたはログ解析から）
    {
      last_hour: rand(100..300), # ダミーデータ
      last_24h: rand(100..300),
      status: "good"
    }
  end

  def active_connections
    # TODO: アクティブな接続数を取得
    {
      current: rand(10..50), # ダミーデータ
      max: 100
    }
  end

  def requests_per_minute
    # TODO: 実際のリクエスト数を取得（ログ解析から）
    {
      current: rand(50..200), # ダミーデータ
      average: rand(100..150),
      peak: rand(300..500)
    }
  end

  def database_health
    {
      connected: database_connected?,
      response_time: database_response_time,
      connections: database_connections
    }
  end

  def external_api_health
    {
      shlink_api: shlink_api_health
    }
  end

  def background_job_health
    failed_jobs = SolidQueue::FailedExecution.count
    {
      failed_jobs: failed_jobs,
      status: failed_jobs > 10 ? "warning" : "healthy"
    }
  rescue StandardError
    { status: "error", error: "バックグラウンドジョブ情報取得不可" }
  end

  def database_connected?
    ActiveRecord::Base.connection.active?
  rescue StandardError
    false
  end

  def database_response_time
    start_time = Time.current
    ActiveRecord::Base.connection.execute("SELECT 1")
    ((Time.current - start_time) * 1000).round(2)
  rescue StandardError
    nil
  end

  def database_connections
    # MySQL用の接続数取得
    return nil unless database_connected?

    result = ActiveRecord::Base.connection.execute('SHOW STATUS LIKE "Threads_connected"')
    result.first&.last&.to_i
  rescue StandardError
    nil
  end

  def shlink_api_health
    # TODO: Shlink API の健康状態をチェック
    {
      status: "healthy",
      last_check: Time.current
    }
  end

  def cpu_core_count
    return 1 unless File.exist?("/proc/cpuinfo")

    File.read("/proc/cpuinfo").scan(/^processor\s*:/).size
  rescue StandardError
    1
  end

  def format_bytes(bytes)
    units = %w[B KB MB GB TB]
    size = bytes.to_f
    unit_index = 0

    while size >= 1024 && unit_index < units.size - 1
      size /= 1024
      unit_index += 1
    end

    "#{size.round(1)} #{units[unit_index]}"
  end

  def memory_status(usage_percent)
    case usage_percent
    when 0..70
      "good"
    when 71..85
      "warning"
    else
      "critical"
    end
  end

  def disk_status(usage_percent)
    case usage_percent
    when 0..70
      "good"
    when 71..85
      "warning"
    else
      "critical"
    end
  end

  def cpu_status(usage_percent)
    case usage_percent
    when 0..70
      "good"
    when 71..90
      "warning"
    else
      "critical"
    end
  end

  def system_command_available?(command)
    system("which #{command} > /dev/null 2>&1")
  end
end
