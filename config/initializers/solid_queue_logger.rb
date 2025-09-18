# Solid Queue ログ設定 - Railsと同じフォーマットにする
Rails.application.configure do
  # 本番環境と開発環境でSolid Queueのログ設定をカスタマイズ
  if Rails.env.production? || Rails.env.development?
    Rails.application.config.after_initialize do
      # SolidQueue用のロガーを設定
      if defined?(SolidQueue)
        # Railsアプリと同じログファイル名を使用（jobsサフィックス付き）
        default_log_file = Rails.env.production? ? "production.log" : "development.log"
        log_file_name = ENV.fetch("RAILS_LOG_FILE", default_log_file)
        log_file_name = log_file_name.sub(/\.log$/, "-jobs.log") unless log_file_name.include?("jobs")

        # STDOUTロガー（日時付きフォーマット）
        stdout_logger = Logger.new(STDOUT)
        stdout_logger.formatter = proc do |severity, datetime, progname, msg|
          # Railsと同じフォーマット: [タイムスタンプ] レベル: メッセージ
          "[#{datetime.strftime('%Y-%m-%d %H:%M:%S.%3N %Z')}] #{severity}: #{msg}\n"
        end

        begin
          # ファイルロガー（日時付きフォーマット）
          log_file_path = Rails.root.join("log", log_file_name)
          FileUtils.mkdir_p(log_file_path.dirname) unless log_file_path.dirname.exist?

          file_logger = Logger.new(log_file_path, "daily")
          file_logger.formatter = proc do |severity, datetime, progname, msg|
            # Railsと同じフォーマット: [タイムスタンプ] レベル: メッセージ
            "[#{datetime.strftime('%Y-%m-%d %H:%M:%S.%3N %Z')}] #{severity}: #{msg}\n"
          end

          # SolidQueueにBroadcastLoggerを設定（STDOUTとファイル両方に出力）
          solid_queue_logger = ActiveSupport::BroadcastLogger.new(file_logger, stdout_logger)

          # ログレベルを設定
          log_level = ENV.fetch("SOLID_QUEUE_LOG_LEVEL", "info").to_sym
          solid_queue_logger.level = Logger.const_get(log_level.to_s.upcase)

          # SolidQueueのロガーを設定
          SolidQueue.logger = solid_queue_logger

          Rails.logger.info "✅ SolidQueue logger initialized with Rails-compatible format: #{log_file_path}"
        rescue => e
          # ファイルログに失敗した場合はSTDOUTのみ
          SolidQueue.logger = stdout_logger
          Rails.logger.warn "⚠️  Warning: SolidQueue file logging failed (#{e.message}), using STDOUT only"
        end
      end
    end
  end
end
