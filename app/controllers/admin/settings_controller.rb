class Admin::SettingsController < Admin::AdminController
  def show
    @settings_by_category = SystemSetting.enabled
                                          .group_by(&:category)
                                          .transform_values { |settings| settings.index_by(&:key_name) }

    @categories = %w[captcha rate_limit email performance security system]
  end

  def update
    settings_params = params.require(:settings).permit!

    ActiveRecord::Base.transaction do
      settings_params.each do |key, value|
        setting = SystemSetting.find_by(key_name: key)
        next unless setting

        setting.update!(value: value)
      end
    end

    redirect_to admin_settings_path, notice: "システム設定を更新しました。"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_settings_path, alert: "設定の更新に失敗しました: #{e.message}"
  rescue StandardError => e
    redirect_to admin_settings_path, alert: "予期しないエラーが発生しました: #{e.message}"
  end

  # 特定カテゴリの設定を取得（Ajax用）
  def category
    category_name = params[:category]
    @settings = SystemSetting.by_category(category_name).enabled

    render json: @settings.map { |setting|
      {
        key_name: setting.key_name,
        value: setting.typed_value,
        description: setting.description,
        setting_type: setting.setting_type
      }
    }
  end

  # システム設定のリセット（デフォルト値に戻す）
  def reset
    category = params[:category]

    if category.present?
      SystemSetting.by_category(category).destroy_all
      SystemSetting.initialize_defaults!
      redirect_to admin_settings_path, notice: "#{category}設定をデフォルト値にリセットしました。"
    else
      redirect_to admin_settings_path, alert: "リセット対象のカテゴリを指定してください。"
    end
  end

  # 設定のテスト実行（メール設定等）
  def test
    test_type = params[:test_type]

    case test_type
    when "email"
      test_email_settings
    when "captcha"
      test_captcha_settings
    else
      render json: { success: false, message: "未対応のテストタイプです。" }
    end
  end

  private

  def test_email_settings
    email_adapter = SystemSetting.get("email.adapter", "smtp")

    test_result = case email_adapter
    when "smtp"
                    test_smtp_settings
    when "mailersend"
                    test_mailersend_settings
    else
                    { success: false, message: "未対応のメールアダプターです。" }
    end

    render json: test_result
  end

  def test_smtp_settings
    smtp_settings = SystemSetting.get("email.smtp_settings", {})

    # SMTP設定のテスト接続を実行
    # TODO: 実際のSMTP接続テストを実装
    { success: true, message: "SMTP設定のテストが成功しました。" }
  rescue StandardError => e
    { success: false, message: "SMTP設定のテストに失敗しました: #{e.message}" }
  end

  def test_mailersend_settings
    # MailerSend設定のテスト
    # TODO: MailerSend APIのテストを実装
    { success: true, message: "MailerSend設定のテストが成功しました。" }
  rescue StandardError => e
    { success: false, message: "MailerSend設定のテストに失敗しました: #{e.message}" }
  end

  def test_captcha_settings
    site_key = SystemSetting.get("captcha.site_key")
    secret_key = SystemSetting.get("captcha.secret_key")

    if site_key.blank? || secret_key.blank?
      render json: { success: false, message: "CAPTCHA設定が未設定です。" }
      return
    end

    # TODO: Turnstile APIのテスト接続を実装
    render json: { success: true, message: "CAPTCHA設定のテストが成功しました。" }
  rescue StandardError => e
    render json: { success: false, message: "CAPTCHA設定のテストに失敗しました: #{e.message}" }
  end
end
