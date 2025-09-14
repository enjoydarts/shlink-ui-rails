class DeviseMailerJob < ApplicationJob
  queue_as :mailers

  # Deviseとの互換性のためのdeliverメソッド
  def deliver
    self
  end

  # リトライ設定（最大3回、指数バックオフ）
  retry_on MailAdapter::BaseAdapter::Error, wait: 1.second, attempts: 3

  def perform(method_name, record, token = nil, opts = {})
    Rails.logger.info("🚀 DeviseMailerJob開始: #{method_name} for #{record.class.name}##{record.id}")
    Rails.logger.debug("📨 DeviseMailerJob詳細: method=#{method_name}, record_id=#{record.id}, token_present=#{!token.nil?}, opts=#{opts}")

    begin
      # Deviseメールオブジェクトを作成
      Rails.logger.debug("📧 Deviseメールオブジェクトを作成中...")

      # JOBSコンテナでDeviseマッピングを確実に初期化
      unless Devise.mappings.key?(:user)
        Rails.logger.info("🔧 Deviseマッピングを初期化中...")
        # Devise設定を強制リロード
        Rails.application.reload_routes!
        Devise.setup do |config|
          # 必要に応じて設定を再読み込み
        end
      end

      # Deviseのマッピングを確実に設定
      mapping_name = :user
      Rails.logger.debug("🗺️ Using mapping: #{mapping_name}")

      # optsを確実にHashにしてマッピングを設定
      opts = opts.to_h if opts.respond_to?(:to_h)
      opts = {} unless opts.is_a?(Hash)
      opts = opts.merge(mapping: mapping_name)
      Rails.logger.debug("🗺️ Devise mapping set: #{mapping_name}")

      mail_object = if token
                      Devise::Mailer.public_send(method_name, record, token, opts)
      else
                      Devise::Mailer.public_send(method_name, record, opts)
      end

      mail_message = mail_object.message
      Rails.logger.debug("📮 メール情報: subject='#{mail_message.subject}', to=#{mail_message.to}, from=#{mail_message.from}")

      # アダプタ経由でメール送信
      Rails.logger.debug("🔧 MailAdapterを作成中...")
      adapter = MailAdapter::Factory.create_adapter
      Rails.logger.info("✉️  使用アダプタ: #{adapter.class.name}")

      Rails.logger.debug("📤 メール送信開始...")
      adapter.deliver_mail(mail_object)
      Rails.logger.debug("📤 メール送信完了")

      Rails.logger.info("✅ DeviseMailerJob完了: #{method_name} for #{record.class.name}##{record.id}")
    rescue MailAdapter::BaseAdapter::Error => e
      Rails.logger.error("❌ DeviseMailerJob: アダプタエラー - #{e.message}")
      Rails.logger.debug("🔍 アダプタエラー詳細: #{e.class.name} - #{e.backtrace.first(5).join('\n')}")

      # アダプタエラーの場合はリトライ
      raise e
    rescue StandardError => e
      Rails.logger.error("❌ DeviseMailerJob: 予期しないエラー - #{e.message}")
      Rails.logger.error("🔍 エラー詳細: #{e.class.name}")
      Rails.logger.debug("📋 スタックトレース:\n#{e.backtrace.join("\n")}")

      # フォールバック：従来のSMTP送信を試行
      begin
        Rails.logger.warn("⚠️  DeviseMailerJob: フォールバック送信を実行（原因: #{e.message}）")
        Rails.logger.debug("🔄 フォールバック詳細: ActionMailer.delivery_method=#{ActionMailer::Base.delivery_method}")
        mail_object.deliver_now
        Rails.logger.info("✅ DeviseMailerJob: フォールバック送信完了（MailerSend失敗のためSMTP使用）")
      rescue StandardError => fallback_error
        Rails.logger.error("❌ DeviseMailerJob: フォールバック送信も失敗 - #{fallback_error.message}")
        Rails.logger.debug("🔍 フォールバックエラー詳細: #{fallback_error.class.name} - #{fallback_error.backtrace.first(3).join('\n')}")
        raise e # 元のエラーを再発生
      end
    end
  end
end
