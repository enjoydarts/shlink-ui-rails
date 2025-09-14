# Devise lockable configuration with SystemSetting integration

Rails.application.reloader.to_prepare do
  # DeviseとSystemSettingを連動させる設定の統一化

  # Devise lockableの設定をSystemSettingから動的に設定
  if defined?(SystemSetting)
    begin
      # ログイン試行回数の上限をSystemSettingから取得
      devise_max_attempts = SystemSetting.get("security.max_login_attempts", 5)
      Devise.maximum_attempts = devise_max_attempts.to_i

      # アカウントロック解除時間をSystemSettingから取得
      unlock_hours = SystemSetting.get("security.account_lockout_time", 30)
      Devise.unlock_in = unlock_hours.to_i.minutes

      # パスワード最小長をSystemSettingから取得
      password_min_length = SystemSetting.get("security.password_min_length", 8)
      Devise.password_length = password_min_length.to_i..128

      # セッション有効期限をSystemSettingから取得
      session_timeout = SystemSetting.get("security.session_timeout_hours", 24)
      Devise.timeout_in = session_timeout.to_i.hours

      Rails.logger.info "Devise settings updated: max_attempts=#{Devise.maximum_attempts}, unlock_in=#{Devise.unlock_in}, password_length=#{Devise.password_length}, timeout_in=#{Devise.timeout_in}"
    rescue => e
      Rails.logger.warn "Failed to configure Devise from SystemSetting: #{e.message}"
      # デフォルト値を使用
      Devise.maximum_attempts = 5
      Devise.unlock_in = 30.minutes
      Devise.password_length = 8..128
      Devise.timeout_in = 24.hours
    end
  else
    # SystemSettingが利用できない場合はデフォルト値
    Devise.maximum_attempts = 5
    Devise.unlock_in = 30.minutes
    Devise.password_length = 8..128
    Devise.timeout_in = 24.hours
  end
end

# Deviseのロック機能とRack::Attackの連携
module Devise
  module Models
    module Lockable
      # アカウントがロックされた際のフック
      def lock_access!
        super
        Rails.logger.info "Account locked: #{email} (failed attempts: #{failed_attempts})"

        # 必要に応じてRack::Attackのカウンターもリセット
        # ユーザーがロックされた場合、IP制限も一時的に緩和することもできる
      end

      # アカウントロックが解除された際のフック
      def unlock_access!
        super
        Rails.logger.info "Account unlocked: #{email}"
      end
    end
  end
end
