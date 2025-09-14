module MailAdapter
  # Letter Opener用のメール送信アダプタ
  # 開発環境でメールを実際に送信せず、ブラウザで確認できるようにする
  class LetterOpenerAdapter < BaseAdapter
    def initialize
      @name = "Letter Opener"
      @identifier = "letter_opener"
      Rails.logger.info("[#{@name}] Letter Openerアダプタを初期化")
    end

    # Letter Openerアダプタが利用可能かチェック
    # @return [Boolean] 開発環境の場合のみtrue
    def available?
      result = Rails.env.development?
      Rails.logger.debug("[#{@name}] 利用可能性チェック: #{result} (開発環境: #{Rails.env.development?})")
      result
    end

    # Letter Openerアダプタの設定が完了しているかチェック
    # @return [Boolean] Letter Openerは設定不要なので常にtrue
    def configured?
      Rails.logger.debug("[#{@name}] 設定チェック: Letter Openerは設定不要")
      true
    end

    # Letter Openerを使ってメールを送信（実際は表示）
    # @param mail [Mail::Message] 送信するメールオブジェクト
    # @return [Boolean] 送信成功の場合true
    def deliver_mail(mail)
      Rails.logger.info("[#{@name}] Letter Opener経由でメール送信開始")
      Rails.logger.info("[#{@name}] 宛先: #{mail.to&.join(', ')}")
      Rails.logger.info("[#{@name}] 件名: #{mail.subject}")

      begin
        # Rails標準のdeliveryメソッドを使用
        # letter_opener_webが設定されていれば自動的に使用される
        mail.deliver_now

        Rails.logger.info("[#{@name}] Letter Openerでメール送信完了")
        Rails.logger.info("[#{@name}] メール確認URL: http://localhost:3000/letter_opener")

        true
      rescue StandardError => e
        Rails.logger.error("[#{@name}] Letter Openerメール送信中にエラー発生: #{e.message}")
        Rails.logger.error("[#{@name}] #{e.backtrace.first(5).join('\n')}")
        raise Error.new("Letter Openerメール送信に失敗: #{e.message}")
      end
    end

    # Letter Openerアダプタの設定情報を取得
    # @return [Hash] 設定情報
    def configuration_info
      {
        adapter: @identifier,
        name: @name,
        environment: Rails.env,
        available: available?,
        configured: configured?,
        description: "開発環境専用。メールをブラウザで確認できます。",
        access_url: "http://localhost:3000/letter_opener"
      }
    end

    # Letter Openerアダプタの詳細情報を取得
    # @return [Hash] 詳細情報
    def adapter_details
      {
        **configuration_info,
        features: [
          "開発環境専用",
          "実際のメール送信なし",
          "ブラウザでメール確認",
          "設定不要"
        ]
      }
    end

    # Letter Openerアダプタの接続テスト
    # @return [Boolean] 開発環境であれば常にtrue
    def test_connection
      Rails.logger.info("[#{@name}] 接続テスト開始")

      if Rails.env.development?
        Rails.logger.info("[#{@name}] 接続テスト成功: 開発環境で利用可能")
        true
      else
        Rails.logger.warn("[#{@name}] 接続テスト失敗: Letter Openerは開発環境でのみ利用可能")
        false
      end
    end
  end
end
