module MailAdapter
  # メール送信アダプタのファクトリクラス
  # 設定に基づいて適切なメール送信アダプタを選択・生成する
  class Factory
    # ファクトリエラークラス
    class FactoryError < StandardError; end

    # サポートされているアダプタタイプ
    SUPPORTED_ADAPTERS = %w[letter_opener smtp mailersend].freeze

    class << self
      # 設定に基づいてメール送信アダプタを作成
      # @return [MailAdapter::BaseAdapter] 設定されたアダプタのインスタンス
      # @raise [FactoryError] 設定が無効な場合
      def create_adapter
        adapter_type = determine_adapter_type

        Rails.logger.info("🏭 [MailAdapter::Factory] #{adapter_type}アダプタを作成中")
        Rails.logger.debug("🔧 [MailAdapter::Factory] アダプタタイプ詳細: #{adapter_type}")

        adapter = case adapter_type
        when "letter_opener"
                    Rails.logger.debug("📭 [MailAdapter::Factory] LetterOpenerAdapterを初期化")
                    LetterOpenerAdapter.new
        when "smtp"
                    Rails.logger.debug("📮 [MailAdapter::Factory] SmtpAdapterを初期化")
                    SmtpAdapter.new
        when "mailersend"
                    Rails.logger.debug("📨 [MailAdapter::Factory] MailersendAdapterを初期化")
                    MailersendAdapter.new
        else
                    raise FactoryError.new("未対応のアダプタタイプ: #{adapter_type}")
        end

        # アダプタの利用可能性をチェック
        Rails.logger.debug("✅ [MailAdapter::Factory] アダプタの利用可能性をチェック中...")
        unless adapter.available?
          Rails.logger.error("❌ [MailAdapter::Factory] アダプタ利用不可: #{adapter_type}")
          raise FactoryError.new("#{adapter_type}アダプタは利用できません（設定または依存関係を確認してください）")
        end

        # 設定が正しいかチェック
        Rails.logger.debug("⚙️  [MailAdapter::Factory] アダプタ設定をチェック中...")
        unless adapter.configured?
          Rails.logger.error("❌ [MailAdapter::Factory] アダプタ設定不備: #{adapter_type}")
          raise FactoryError.new("#{adapter_type}アダプタの設定が不完全です")
        end

        Rails.logger.info("✅ [MailAdapter::Factory] #{adapter_type}アダプタの作成が完了")
        adapter
      rescue StandardError => e
        Rails.logger.error("❌ [MailAdapter::Factory] アダプタ作成中にエラーが発生: #{e.message}")
        Rails.logger.debug("🔍 [MailAdapter::Factory] エラー詳細: #{e.class.name} - #{e.backtrace.first(3).join('\n')}")
        raise
      end

      private

      # 使用するアダプタタイプを決定
      # @return [String] アダプタタイプ ('letter_opener', 'smtp', 'mailersend')
      def determine_adapter_type
        # システム設定から決定（開発環境でも動的に切り替え可能）
        default_adapter = Rails.env.development? ? "letter_opener" : "smtp"
        configured_type = SystemSetting.get("email.adapter", default_adapter)&.to_s&.downcase

        if SUPPORTED_ADAPTERS.include?(configured_type)
          Rails.logger.info("[MailAdapter::Factory] #{configured_type}アダプタを使用")
          configured_type
        else
          Rails.logger.warn("[MailAdapter::Factory] 不明な配信方式設定: #{configured_type}. #{default_adapter}を使用します.")
          default_adapter
        end
      rescue StandardError => e
        default_adapter = Rails.env.development? ? "letter_opener" : "smtp"
        Rails.logger.error("[MailAdapter::Factory] アダプタタイプ決定中にエラー: #{e.message}. #{default_adapter}を使用します.")
        default_adapter
      end
    end
  end
end
