# 統一システム設定管理

Rails.application.reloader.to_prepare do
  begin
    # ApplicationConfigを使用してシステム設定を適用
    if defined?(ApplicationConfig)
      ApplicationConfig.reload!
    else
      # フォールバック設定
      Time.zone = "Tokyo"
      Rails.logger.level = Logger::INFO
    end
  rescue => e
    Rails.logger.warn "Failed to configure system settings: #{e.message}"
    # デフォルト値を使用
    Time.zone = "Tokyo"
    Rails.logger.level = Logger::INFO
  end
end
