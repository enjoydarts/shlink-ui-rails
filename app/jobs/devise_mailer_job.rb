class DeviseMailerJob < ApplicationJob
  queue_as :mailers

  # リトライ設定（最大3回、指数バックオフ）
  retry_on MailAdapter::BaseAdapter::Error, wait: 1.second, attempts: 3

  def perform(method_name, record, token = nil, opts = {})
    Rails.logger.info("DeviseMailerJob開始: #{method_name} for #{record.class.name}##{record.id}")

    begin
      # Deviseメールオブジェクトを作成
      mail_object = if token
                      Devise::Mailer.public_send(method_name, record, token, opts)
      else
                      Devise::Mailer.public_send(method_name, record, opts)
      end

      # アダプタ経由でメール送信
      adapter = MailAdapter::Factory.create_adapter
      adapter.deliver_mail(mail_object)

      Rails.logger.info("DeviseMailerJob完了: #{method_name} for #{record.class.name}##{record.id}")
    rescue MailAdapter::BaseAdapter::Error => e
      Rails.logger.error("DeviseMailerJob: アダプタエラー - #{e.message}")

      # アダプタエラーの場合はリトライ
      raise e
    rescue StandardError => e
      Rails.logger.error("DeviseMailerJob: 予期しないエラー - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      # フォールバック：従来のSMTP送信を試行
      begin
        Rails.logger.info("DeviseMailerJob: フォールバック送信を実行")
        mail_object.deliver_now
        Rails.logger.info("DeviseMailerJob: フォールバック送信完了")
      rescue StandardError => fallback_error
        Rails.logger.error("DeviseMailerJob: フォールバック送信も失敗 - #{fallback_error.message}")
        raise e # 元のエラーを再発生
      end
    end
  end
end
