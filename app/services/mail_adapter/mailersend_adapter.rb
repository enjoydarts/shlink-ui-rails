require "mailersend-ruby"

module MailAdapter
  # MailerSend API経由でメール送信を行うアダプタ
  class MailersendAdapter < BaseAdapter
    # MailerSend APIエラークラス
    class MailersendError < Error; end

    def initialize
      begin
        @api_key = SystemSetting.get("email.mailersend_api_key", "")
        @from_email = SystemSetting.get("email.from_address", "noreply@example.com")
        @from_name = SystemSetting.get("system.site_name", "Shlink-UI-Rails")
      rescue StandardError => e
        log_error("MailerSend設定の初期化中にエラーが発生", e)
        @api_key = nil
        @from_email = nil
        @from_name = nil
      end

      # MailerSend v3では初期化時にクライアントを作成する必要はない
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
        # MailerSend v3対応: ClientとEmailオブジェクトを構築
        Rails.logger.info("🔑 MailerSend API Key (最初4文字): #{@api_key[0..3]}...")
        Rails.logger.info("📧 From Email: #{@from_email}")
        Rails.logger.info("👤 From Name: #{@from_name}")

        ms_client = Mailersend::Client.new(@api_key)
        email = Mailersend::Email.new(ms_client)

        # 送信者設定
        email.add_from("email" => @from_email, "name" => @from_name)

        # 受信者設定
        email.add_recipients("email" => to_email)

        # CC設定
        if mail.cc.present?
          mail.cc.each do |cc_email|
            email.add_cc("email" => cc_email)
          end
        end

        # BCC設定
        if mail.bcc.present?
          mail.bcc.each do |bcc_email|
            email.add_bcc("email" => bcc_email)
          end
        end

        # 件名・本文設定
        email.add_subject(subject)

        # HTMLとテキスト本文の設定
        if mail.multipart?
          # マルチパートメールの場合、各パートから内容を抽出
          mail.parts.each do |part|
            case part.content_type
            when /text\/html/
              email.add_html(part.body.decoded)
            when /text\/plain/
              email.add_text(part.body.decoded)
            end
          end
        else
          # シングルパートメールの場合
          if mail.html_part&.body
            email.add_html(mail.html_part.body.decoded)
          end

          if mail.text_part&.body
            email.add_text(mail.text_part.body.decoded)
          elsif !mail.html_part && mail.body
            # プレーンテキストメールの場合
            email.add_text(mail.body.decoded)
          end
        end

        # MailerSend APIを呼び出し（v3対応）
        Rails.logger.info("🚀 MailerSend API呼び出し開始")
        response = email.send
        Rails.logger.info("📡 MailerSend API レスポンス: #{response.inspect}")
        Rails.logger.info("📡 MailerSend API レスポンスクラス: #{response.class.name}")

        # レスポンスの詳細をログ出力
        if response.respond_to?(:body)
          Rails.logger.info("📄 Response body: #{response.body}")
        end
        if response.respond_to?(:status)
          Rails.logger.info("📊 Response status: #{response.status}")
        end

        # レスポンスの成功/失敗判定
        if response.respond_to?(:message) && response.message.present?
          error_msg = "MailerSend API送信失敗: #{response.message}"
          log_error(error_msg)
          raise MailersendError.new(error_msg)
        end

        log_info("MailerSend API経由でメール送信が完了: #{subject} - Response: #{response.inspect}")
        true
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
  end
end
