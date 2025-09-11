module MailAdapter
  # メール送信アダプタの基底クラス
  # 異なるメール送信方式（SMTP、MailerSend等）の共通インターフェースを定義
  class BaseAdapter
    # メール送信の基本エラークラス
    class Error < StandardError
      attr_reader :original_error

      def initialize(message, original_error = nil)
        super(message)
        @original_error = original_error
      end
    end

    def initialize
      raise NotImplementedError, "#{self.class}#initialize must be implemented"
    end

    # メール送信のメインメソッド
    # @param mail_object [ActionMailer::MessageDelivery] Railsメールオブジェクト
    # @return [Boolean] 送信成功時はtrue
    # @raise [MailAdapter::BaseAdapter::Error] 送信失敗時
    def deliver_mail(mail_object)
      raise NotImplementedError, "#{self.class}#deliver_mail must be implemented"
    end

    # アダプタが利用可能かチェック
    # @return [Boolean] 利用可能な場合はtrue
    def available?
      raise NotImplementedError, "#{self.class}#available? must be implemented"
    end

    # アダプタの設定が正しいかチェック
    # @return [Boolean] 設定が正しい場合はtrue
    def configured?
      raise NotImplementedError, "#{self.class}#configured? must be implemented"
    end

    protected

    # ログ出力用のヘルパーメソッド
    def log_info(message)
      Rails.logger.info("[#{self.class.name}] #{message}")
    end

    def log_error(message, error = nil)
      if error
        Rails.logger.error("[#{self.class.name}] #{message}: #{error.message}")
        Rails.logger.error(error.backtrace.join("\n")) if error.backtrace
      else
        Rails.logger.error("[#{self.class.name}] #{message}")
      end
    end
  end
end
