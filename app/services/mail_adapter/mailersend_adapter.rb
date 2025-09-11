require "mailersend-ruby"

module MailAdapter
  # MailerSend API経由でメール送信を行うアダプタ
  class MailersendAdapter < BaseAdapter
    # MailerSend APIエラークラス
    class MailersendError < Error; end

    def initialize
      begin
        @api_key = Settings.mailersend.api_key
        @from_email = Settings.mailersend.from_email
        @from_name = Settings.mailersend.from_name
      rescue StandardError => e
        log_error("MailerSend設定の初期化中にエラーが発生", e)
        @api_key = nil
        @from_email = nil
        @from_name = nil
      end

      if configured?
        @client = ::Mailersend::Email.new
        @client.api_token = @api_key
      end
    end

    # MailerSend API経由でメール送信を実行
    # @param mail_object [ActionMailer::MessageDelivery] Railsメールオブジェクト
    # @return [Boolean] 送信成功時はtrue
    # @raise [MailAdapter::BaseAdapter::Error] 送信失敗時
    def deliver_mail(mail_object)
      unless configured?
        raise MailersendError.new("MailerSend設定が不完全です")
      end

      # Mailオブジェクトから情報を抽出
      mail = mail_object.message
      subject = mail.subject
      to_email = extract_first_recipient(mail)

      log_info("MailerSend API経由でメール送信を開始: #{subject} -> #{to_email}")

      begin
        # MailerSend用のペイロードを構築
        payload = build_mailersend_payload(mail)

        # MailerSend APIを呼び出し
        response = @client.send_email(payload)

        if response.success?
          log_info("MailerSend API経由でメール送信が完了: #{subject}")
          true
        else
          error_msg = "MailerSend API送信失敗: #{response.message}"
          log_error(error_msg)
          raise MailersendError.new(error_msg)
        end
      rescue ::Mailersend::Error => e
        error_msg = "MailerSend APIエラー: #{e.message}"
        log_error(error_msg, e)
        raise MailersendError.new(error_msg, e)
      rescue StandardError => e
        error_msg = "MailerSend送信で予期しないエラーが発生: #{e.message}"
        log_error(error_msg, e)
        raise MailersendError.new(error_msg, e)
      end
    end

    # MailerSendアダプタが利用可能かチェック
    # @return [Boolean] 利用可能な場合はtrue
    def available?
      configured? && gem_available?
    end

    # MailerSend設定が正しいかチェック
    # @return [Boolean] 設定が正しい場合はtrue
    def configured?
      @api_key.present? &&
        @from_email.present? &&
        @from_name.present?
    rescue StandardError => e
      log_error("MailerSend設定の確認中にエラーが発生", e)
      false
    end

    private

    # MailerSend gemが利用可能かチェック
    def gem_available?
      !defined?(::Mailersend).nil? && !defined?(::Mailersend::Email).nil?
    end

    # メールの最初の受信者を抽出
    def extract_first_recipient(mail)
      return mail.to.first if mail.to.present?
      return mail.cc.first if mail.cc.present?
      return mail.bcc.first if mail.bcc.present?
      "unknown@example.com"
    end

    # MailerSend API用のペイロードを構築
    def build_mailersend_payload(mail)
      # HTMLとテキストコンテンツを抽出
      html_content = extract_html_content(mail)
      text_content = extract_text_content(mail)

      payload = {
        "from" => {
          "email" => @from_email,
          "name" => @from_name
        },
        "to" => build_recipients(mail.to),
        "subject" => mail.subject || "件名なし"
      }

      # CC、BCCがある場合は追加
      payload["cc"] = build_recipients(mail.cc) if mail.cc.present?
      payload["bcc"] = build_recipients(mail.bcc) if mail.bcc.present?

      # コンテンツを追加（HTMLを優先、フォールバックでテキスト）
      if html_content.present?
        payload["html"] = html_content
        payload["text"] = text_content if text_content.present?
      elsif text_content.present?
        payload["text"] = text_content
      else
        payload["text"] = "このメールにはコンテンツがありません。"
      end

      payload
    end

    # 受信者リストを構築
    def build_recipients(email_addresses)
      return [] unless email_addresses.present?

      email_addresses.map do |email|
        { "email" => email }
      end
    end

    # HTMLコンテンツを抽出
    def extract_html_content(mail)
      if mail.multipart?
        html_part = mail.parts.find { |part| part.content_type =~ /text\/html/ }
        html_part&.body&.decoded
      elsif mail.content_type =~ /text\/html/
        mail.body.decoded
      end
    end

    # テキストコンテンツを抽出
    def extract_text_content(mail)
      if mail.multipart?
        text_part = mail.parts.find { |part| part.content_type =~ /text\/plain/ }
        text_part&.body&.decoded
      elsif mail.content_type =~ /text\/plain/
        mail.body.decoded
      else
        # HTMLからテキストを生成（簡易版）
        html_content = extract_html_content(mail)
        html_content&.gsub(/<[^>]*>/, "")&.strip
      end
    end
  end
end
