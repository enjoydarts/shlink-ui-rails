module MailAdapter
  # メール送信アダプタのファクトリクラス
  # 設定に基づいて適切なメール送信アダプタを選択・生成する
  class Factory
    # ファクトリエラークラス
    class FactoryError < StandardError; end

    # サポートされているアダプタタイプ
    SUPPORTED_ADAPTERS = %w[smtp mailersend].freeze

    class << self
      # 設定に基づいてメール送信アダプタを作成
      # @return [MailAdapter::BaseAdapter] 設定されたアダプタのインスタンス
      # @raise [FactoryError] 設定が無効な場合
      def create_adapter
        adapter_type = determine_adapter_type

        Rails.logger.info("[MailAdapter::Factory] #{adapter_type}アダプタを作成中")

        adapter = case adapter_type
        when "smtp"
                    SmtpAdapter.new
        when "mailersend"
                    MailersendAdapter.new
        else
                    raise FactoryError.new("未対応のアダプタタイプ: #{adapter_type}")
        end

        # アダプタの利用可能性をチェック
        unless adapter.available?
          raise FactoryError.new("#{adapter_type}アダプタは利用できません（設定または依存関係を確認してください）")
        end

        # 設定が正しいかチェック
        unless adapter.configured?
          raise FactoryError.new("#{adapter_type}アダプタの設定が不完全です")
        end

        Rails.logger.info("[MailAdapter::Factory] #{adapter_type}アダプタの作成が完了")
        adapter
      rescue StandardError => e
        Rails.logger.error("[MailAdapter::Factory] アダプタ作成中にエラーが発生: #{e.message}")
        raise
      end

      private

      # 使用するアダプタタイプを決定
      # @return [String] アダプタタイプ ('smtp' または 'mailersend')
      def determine_adapter_type
        # 開発・テスト環境では常にSMTPを使用
        return "smtp" unless Rails.env.production?

        # 本番環境では設定値に基づいて決定
        configured_type = Settings.mail_delivery_method&.to_s&.downcase

        if SUPPORTED_ADAPTERS.include?(configured_type)
          configured_type
        else
          Rails.logger.warn("[MailAdapter::Factory] 不明な配信方式設定: #{configured_type}. SMTPを使用します.")
          "smtp"
        end
      rescue StandardError => e
        Rails.logger.error("[MailAdapter::Factory] アダプタタイプ決定中にエラー: #{e.message}. SMTPを使用します.")
        "smtp"
      end
    end
  end
end
