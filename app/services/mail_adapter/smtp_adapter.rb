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
      # 開発環境では常にtrue（letter_opener_webが使用されるため）
      if Rails.env.development?
        return true
      end

      # Factoryが決定するアダプタタイプをチェック
      # SMTPアダプタ以外が選択されている場合は、SMTP設定チェックは不要
      begin
        adapter_type = determine_factory_adapter_type
        if adapter_type != "smtp"
          return true
        end
      rescue StandardError => e
        log_error("アダプタタイプの確認中にエラーが発生", e)
        # エラー時はSMTP設定をチェックする（デフォルト動作）
      end

      # SMTPアダプタ使用時は必要な設定があるかチェック
      SystemSetting.get("email.smtp_address", "").present? &&
        SystemSetting.get("email.smtp_user_name", "").present? &&
        SystemSetting.get("email.smtp_password", "").present?
    rescue StandardError => e
      log_error("SMTP設定の確認中にエラーが発生", e)
      false
    end

    private

    # Factoryが決定するアダプタタイプを取得
    # @return [String] アダプタタイプ
    def determine_factory_adapter_type
      # システム設定から決定（Factoryと同じロジック）
      default_adapter = Rails.env.development? ? "letter_opener" : "smtp"
      configured_type = SystemSetting.get("email.adapter", default_adapter)&.to_s&.downcase

      if MailAdapter::Factory::SUPPORTED_ADAPTERS.include?(configured_type)
        configured_type
      else
        default_adapter
      end
    end
  end
end
