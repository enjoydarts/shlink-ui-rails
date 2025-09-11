require "net/smtp"
require "timeout"

module MailAdapter
  # SMTP経由でメール送信を行うアダプタ
  # 従来のRails ActionMailer SMTP送信方式を使用
  class SmtpAdapter < BaseAdapter
    def initialize
      # SMTP設定は既存のRails設定を使用するため、特別な初期化は不要
    end

    # SMTP経由でメール送信を実行
    # @param mail_object [ActionMailer::MessageDelivery] Railsメールオブジェクト
    # @return [Boolean] 送信成功時はtrue
    # @raise [MailAdapter::BaseAdapter::Error] 送信失敗時
    def deliver_mail(mail_object)
      log_info("SMTP経由でメール送信を開始: #{mail_object.subject}")

      begin
        # Rails標準のdelivery_methodを使用してメール送信
        delivery_result = mail_object.deliver_now

        log_info("SMTP経由でメール送信が完了: #{mail_object.subject}")
        true
      rescue Net::SMTPError, Timeout::Error, SocketError => e
        error_msg = "SMTP送信エラー: #{e.message}"
        log_error(error_msg, e)
        raise Error.new(error_msg, e)
      rescue StandardError => e
        error_msg = "メール送信で予期しないエラーが発生: #{e.message}"
        log_error(error_msg, e)
        raise Error.new(error_msg, e)
      end
    end

    # SMTPアダプタは常に利用可能
    # @return [Boolean] 常にtrue
    def available?
      true
    end

    # SMTP設定が正しいかチェック
    # @return [Boolean] 設定が正しい場合はtrue
    def configured?
      # 開発・テスト環境では設定チェックをスキップ
      return true unless Rails.env.production?

      # 本番環境では必要な設定があるかチェック
      Settings.mailer.address.present? &&
        Settings.mailer.domain.present? &&
        Settings.mailer.user_name.present? &&
        Settings.mailer.password.present?
    rescue StandardError => e
      log_error("SMTP設定の確認中にエラーが発生", e)
      false
    end
  end
end
