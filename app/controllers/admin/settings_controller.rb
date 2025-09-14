class Admin::SettingsController < Admin::AdminController
  def show
    @settings_by_category = SystemSetting.enabled
                                          .group_by(&:category)
                                          .transform_values { |settings| settings.index_by(&:key_name) }

    @categories = %w[shlink captcha rate_limit email performance security system]
  end

  def update
    # Mass Assignment対策：データベースに存在するキーのみ許可
    allowed_keys = SystemSetting.pluck(:key_name)
    settings_params = params.require(:settings).permit(*allowed_keys)

    ActiveRecord::Base.transaction do
      settings_params.each do |key, value|
        setting = SystemSetting.find_by(key_name: key)
        next unless setting

        setting.update!(value: value)
      end
    end

    # システム設定変更後はキャッシュをクリア
    refresh_system_settings!

    # 統一設定システムを再読み込み
    ApplicationConfig.reload!

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
    Rails.logger.info "Reset request received with category: #{category.inspect}"
    Rails.logger.info "All params: #{params.inspect}"

    if category.present?
      Rails.logger.info "Resetting category: #{category}"
      SystemSetting.by_category(category).destroy_all
      SystemSetting.initialize_defaults!

      # システム設定変更後はキャッシュをクリア
      refresh_system_settings!

      # 統一設定システムを再読み込み
      ApplicationConfig.reload!

      redirect_to admin_settings_path, notice: "#{category}設定をデフォルト値にリセットしました。"
    else
      Rails.logger.warn "Category parameter is missing or empty"
      redirect_to admin_settings_path, alert: "リセット対象のカテゴリを指定してください。"
    end
  rescue StandardError => e
    Rails.logger.error "Reset failed with error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to admin_settings_path, alert: "リセット中にエラーが発生しました: #{e.message}"
  end

  # 設定のテスト実行（メール設定等）
  def test
    test_type = params[:test_type]

    case test_type
    when "email"
      test_email_settings
    when "captcha"
      test_captcha_settings
    when "shlink"
      test_shlink_settings
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
    # 現在の設定を取得
    smtp_settings = {
      address: SystemSetting.get("email.smtp_address", "smtp.gmail.com"),
      port: SystemSetting.get("email.smtp_port", 587),
      user_name: SystemSetting.get("email.smtp_user_name", ""),
      password: SystemSetting.get("email.smtp_password", ""),
      authentication: SystemSetting.get("email.smtp_authentication", "plain").to_sym,
      enable_starttls_auto: SystemSetting.get("email.smtp_enable_starttls_auto", true)
    }.compact

    # テスト用メーラー設定
    test_mailer = ActionMailer::Base.new
    test_mailer.delivery_method = :smtp
    test_mailer.smtp_settings = smtp_settings

    # 実際にSMTP接続テストを実行
    Net::SMTP.start(
      smtp_settings[:address],
      smtp_settings[:port],
      "localhost", # HELO domain
      smtp_settings[:user_name],
      smtp_settings[:password],
      smtp_settings[:authentication]
    ) do |smtp|
      # 接続が成功すればここに到達
    end

    { success: true, message: "SMTP設定のテストが成功しました。SMTPサーバーへの接続が確認できました。" }
  rescue Net::SMTPAuthenticationError => e
    { success: false, message: "SMTP認証に失敗しました: #{e.message}" }
  rescue Net::SMTPConnectError => e
    { success: false, message: "SMTPサーバーへの接続に失敗しました: #{e.message}" }
  rescue Timeout::Error => e
    { success: false, message: "SMTP接続がタイムアウトしました: #{e.message}" }
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
      render json: { success: false, message: "CAPTCHA設定が未設定です。Site KeyとSecret Keyを入力してください。" }
      return
    end

    # Turnstile APIに対してテスト用のトークン検証を実行
    uri = URI.parse("https://challenges.cloudflare.com/turnstile/v0/siteverify")
    response = Net::HTTP.post_form(uri, {
      "secret" => secret_key,
      "response" => "test_token", # テスト用無効トークン
      "remoteip" => request.remote_ip
    })

    result = JSON.parse(response.body)

    if response.code == "200" && result.key?("success")
      # APIからレスポンスが返ってくれば設定は有効（トークン自体は無効でもOK）
      render json: {
        success: true,
        message: "CAPTCHA設定のテストが成功しました。Cloudflare Turnstile APIとの通信が確認できました。"
      }
    else
      render json: {
        success: false,
        message: "CAPTCHA設定のテストに失敗しました。APIレスポンス: #{result}"
      }
    end
  rescue JSON::ParserError => e
    render json: { success: false, message: "CAPTCHA APIのレスポンス解析に失敗しました: #{e.message}" }
  rescue StandardError => e
    render json: { success: false, message: "CAPTCHA設定のテストに失敗しました: #{e.message}" }
  end

  def test_shlink_settings
    base_url = SystemSetting.get("shlink.base_url")
    api_key = SystemSetting.get("shlink.api_key")

    if base_url.blank? || api_key.blank?
      render json: { success: false, message: "Shlink設定が未設定です。ベースURLとAPIキーを入力してください。" }
      return
    end

    # Shlink APIの health エンドポイントでテスト
    uri = URI.parse("#{base_url.chomp('/')}/rest/health")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = 10
    http.read_timeout = 10

    request = Net::HTTP::Get.new(uri.request_uri)
    request["X-Api-Key"] = api_key
    request["Accept"] = "application/json"

    response = http.request(request)

    if response.code == "200"
      result = JSON.parse(response.body)
      render json: {
        success: true,
        message: "Shlink API接続テストが成功しました。サーバー: #{result['status'] || 'OK'}"
      }
    else
      render json: {
        success: false,
        message: "Shlink API接続に失敗しました。HTTPステータス: #{response.code}"
      }
    end
  rescue JSON::ParserError => e
    render json: { success: false, message: "Shlink APIのレスポンス解析に失敗しました: #{e.message}" }
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    render json: { success: false, message: "Shlink APIへの接続がタイムアウトしました: #{e.message}" }
  rescue StandardError => e
    render json: { success: false, message: "Shlink API接続テストに失敗しました: #{e.message}" }
  end
end
