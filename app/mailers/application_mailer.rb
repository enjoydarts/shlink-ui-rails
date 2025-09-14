class ApplicationMailer < ActionMailer::Base
  include ConfigShortcuts

  # 統一設定システムから送信者情報を動的に取得
  default from: -> { email_from_address.presence || "from@example.com" }
  layout "mailer"

  private

  def default_from_address
    if Rails.env.development? || Rails.env.test?
      "from@example.com"
    else
      begin
        # 本番環境での設定取得ロジック（必要に応じて実装）
        email_from_address.presence || "from@example.com"
      rescue StandardError => e
        Rails.logger.error "送信者アドレス取得中にエラーが発生しました: #{e.message}"
        "from@example.com"
      end
    end
  end
end
