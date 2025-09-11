class ApplicationMailer < ActionMailer::Base
  # 設定から送信者情報を動的に取得
  default from: -> { default_from_address }
  layout "mailer"

  private

  # デフォルトの送信者アドレスを設定から取得
  def default_from_address
    if Rails.env.production? && Settings.mail_delivery_method == "mailersend"
      # MailerSend使用時は専用設定から取得
      "#{Settings.mailersend.from_name} <#{Settings.mailersend.from_email}>"
    elsif Rails.env.production? && Settings.mailer.from.present?
      # SMTP使用時は設定から取得
      Settings.mailer.from
    else
      # 開発・テスト環境やフォールバック用
      "from@example.com"
    end
  rescue StandardError => e
    Rails.logger.error("送信者アドレス取得中にエラーが発生: #{e.message}")
    "from@example.com"
  end
end
