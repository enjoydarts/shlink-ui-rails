class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable, :omniauthable, omniauth_providers: [ :google_oauth2 ]

  # User roles
  enum :role, {
    normal_user: "normal_user",
    admin: "admin"
  }, default: :normal_user

  validates :name, presence: true, if: :from_omniauth?
  validates :role, inclusion: { in: roles.keys }

  # OAuth methods
  def self.from_omniauth(auth)
    user = where(email: auth.info.email).first_or_initialize do |u|
      u.email = auth.info.email
      u.password = Devise.friendly_token[0, 20]
      u.password_confirmation = u.password
      u.name = auth.info.name
      u.provider = auth.provider
      u.uid = auth.uid
    end

    if user.new_record?
      user.skip_confirmation!
      user.save!
    end

    user
  end

  def from_omniauth?
    provider.present? && uid.present?
  end

  def display_name
    name.presence || email.split("@").first
  end

  def needs_password_setup?
    from_omniauth? && encrypted_password.blank?
  end

  def has_password?
    encrypted_password.present?
  end

  # Association with short URLs
  has_many :short_urls, dependent: :destroy

  # Get user's short URLs ordered by creation date
  def recent_short_urls(limit = nil)
    scope = short_urls.recent
    limit ? scope.limit(limit) : scope
  end

  # Two-Factor Authentication関連メソッド

  # 2FAが有効かどうか
  # @return [Boolean] 2FA有効の場合true
  def two_factor_enabled?
    otp_required_for_login? && otp_secret_key.present?
  end

  # 2FAが必要かどうか（OAuthユーザーは除外される場合がある）
  # @return [Boolean] 2FA必要の場合true
  def requires_two_factor?
    two_factor_enabled? && !skip_two_factor_for_oauth?
  end

  # OAuth認証ユーザーの2FAスキップ判定
  # @return [Boolean] スキップする場合true
  def skip_two_factor_for_oauth?
    # Google認証ユーザーは2FA内包とみなしてスキップする場合の判定
    # 現在は全ユーザーで2FAを要求
    false
  end

  # TOTPコードを検証
  # @param code [String] 6桁のTOTPコード
  # @return [Boolean] 検証成功の場合true
  def verify_totp_code(code)
    TotpService.verify_code(self, code)
  end

  # バックアップコードを検証・使用
  # @param code [String] バックアップコード
  # @return [Boolean] 検証成功の場合true
  def verify_backup_code(code)
    TotpService.verify_backup_code(self, code)
  end

  # 2FAコード（TOTPまたはバックアップ）を検証
  # @param code [String] 認証コード
  # @return [Boolean] 検証成功の場合true
  def verify_two_factor_code(code)
    return false if code.blank?

    # まずTOTPコードを試行
    return true if verify_totp_code(code)
    
    # TOTPが失敗した場合、バックアップコードを試行
    verify_backup_code(code)
  end

  # 2FAを有効化
  # @param verification_code [String] 検証用TOTPコード
  # @return [Boolean] 有効化成功の場合true
  def enable_two_factor!(verification_code)
    TotpService.enable_for(self, verification_code)
  end

  # 2FAを無効化
  # @return [Boolean] 無効化成功の場合true
  def disable_two_factor!
    TotpService.disable_for(self)
  end

  # 新しいバックアップコードを生成
  # @return [Array<String>] バックアップコード配列
  def regenerate_backup_codes!
    TotpService.generate_backup_codes(self)
  end

  # バックアップコードの残り数
  # @return [Integer] 残りバックアップコード数
  def backup_codes_count
    return 0 if otp_backup_codes.blank?
    
    begin
      backup_codes = Rails.application.message_verifier(:backup_codes).verify(otp_backup_codes)
      JSON.parse(backup_codes).size
    rescue StandardError
      0
    end
  end
end
