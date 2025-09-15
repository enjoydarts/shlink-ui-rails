# Database performance configuration using SystemSetting

# アセットプリコンパイル時はスキップ
unless ENV["RAILS_GROUPS"] == "assets"
  Rails.application.reloader.to_prepare do
    if defined?(SystemSetting) && defined?(ActiveRecord::Base)
      begin
        # データベースタイムアウト設定をSystemSettingから取得
        timeout_seconds = SystemSetting.get("performance.database_timeout", 30)

        # MySQLのタイムアウト設定を適用
        ActiveRecord::Base.connection_pool.with_connection do |conn|
          # 接続タイムアウト (秒)
          conn.execute("SET SESSION wait_timeout = #{timeout_seconds}")
          # 対話タイムアウト (秒)
          conn.execute("SET SESSION interactive_timeout = #{timeout_seconds}")
        end

        Rails.logger.info "Database timeout configured: #{timeout_seconds} seconds"
      rescue => e
        Rails.logger.warn "Failed to configure database timeout from SystemSetting: #{e.message}"
      end
    end
  end
end
