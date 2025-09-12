module SystemSettingsHelper
  # システム設定を取得するヘルパーメソッド
  def system_setting(key, default = nil)
    Rails.cache.fetch("system_setting:#{key}", expires_in: SystemSetting.get('performance.cache_ttl', 3600).seconds) do
      SystemSetting.get(key, default)
    end
  end

  # サイト名を取得
  def site_name
    system_setting('system.site_name', 'Shlink-UI-Rails')
  end

  # サイトURLを取得
  def site_url
    system_setting('system.site_url', request.base_url)
  end

  # メンテナンスモードかどうか確認
  def maintenance_mode?
    system_setting('system.maintenance_mode', false)
  end

  # CAPTCHAが有効かどうか確認
  def captcha_enabled?
    system_setting('captcha.enabled', false)
  end

  # レート制限が有効かどうか確認
  def rate_limit_enabled?
    system_setting('rate_limit.enabled', true)
  end

  # ページサイズを取得
  def page_size
    system_setting('performance.page_size', 20)
  end

  # パスワード最小長を取得
  def password_min_length
    system_setting('security.password_min_length', 8)
  end

  # 2FA必須かどうか確認（管理者向け）
  def require_2fa_for_admin?
    system_setting('security.require_2fa_for_admin', true)
  end

  # ユーザーあたりの最大短縮URL数を取得
  def max_short_urls_per_user
    system_setting('performance.max_short_urls_per_user', 1000)
  end

  # デフォルト短縮コード長を取得
  def default_short_code_length
    system_setting('system.default_short_code_length', 5)
  end

  # 許可ドメイン一覧を取得
  def allowed_domains
    system_setting('system.allowed_domains', [])
  end

  # システム設定の変更を反映（キャッシュクリア）
  def refresh_system_settings!
    Rails.cache.delete_matched("system_setting:*")
  end
end