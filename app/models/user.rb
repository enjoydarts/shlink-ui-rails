class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable, :timeoutable, :omniauthable, omniauth_providers: [ :google_oauth2 ]

  # User roles
  enum :role, {
    normal_user: "normal_user",
    admin: "admin"
  }, default: :normal_user

  # Theme preferences
  enum :theme_preference, {
    light: "light",
    dark: "dark",
    system: "system"
  }, default: :system

  validates :name, presence: true, if: :from_omniauth?
  validates :role, inclusion: { in: roles.keys }
  validates :theme_preference, inclusion: { in: theme_preferences.keys }

  # 強固なパスワード要求
  validate :password_strength, if: :password_required? && :should_validate_strong_password?

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

  # 2FAが有効かどうか（TOTP または WebAuthn のいずれかが有効）
  # @return [Boolean] 2FA有効の場合true
  def two_factor_enabled?
    totp_enabled? || webauthn_enabled?
  end

  # TOTP（認証アプリ）が有効かどうか
  # @return [Boolean] TOTP有効の場合true
  def totp_enabled?
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
    # Google認証ユーザーは2FA内包とみなしてスキップ
    from_omniauth? && provider == "google_oauth2"
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
    backup_codes = TotpService.generate_backup_codes(self)
    save!
    backup_codes
  end

  # 新しいバックアップコードを生成（エイリアス）
  # @return [Array<String>] バックアップコード配列
  def regenerate_two_factor_backup_codes!
    regenerate_backup_codes!
  end

  # QRコードを生成
  # @return [String] QRコードのSVG
  def generate_two_factor_qr_code
    TotpService.generate_qr_code(self)
  end

  # 2FAシークレットキーを取得
  # @return [String] Base32エンコードされたシークレットキー
  def two_factor_secret
    TotpService.get_secret(self)
  end

  # バックアップコードを取得
  # @return [Array<String>] バックアップコード配列
  def two_factor_backup_codes
    return [] if otp_backup_codes.blank?

    begin
      backup_codes = Rails.application.message_verifier(:backup_codes).verify(otp_backup_codes)
      JSON.parse(backup_codes)
    rescue StandardError
      []
    end
  end

  # バックアップコードの残り数
  # @return [Integer] 残りバックアップコード数
  def backup_codes_count
    two_factor_backup_codes.size
  end

  # FIDO2/WebAuthn関連メソッド

  # WebAuthnクレデンシャルとの関連付け
  has_many :webauthn_credentials, dependent: :destroy

  # FIDO2セキュリティキーが登録されているか
  # @return [Boolean] 登録済みの場合true
  def webauthn_enabled?
    webauthn_credentials.exists?
  end

  # アクティブなWebAuthnクレデンシャルを取得
  # @return [ActiveRecord::Relation] アクティブなクレデンシャル
  def active_webauthn_credentials
    webauthn_credentials.where(active: true)
  end

  # WebAuthn ID（ユーザーハンドル）を生成・取得
  # @return [String] WebAuthn用のユーザーID
  def webauthn_id
    return webauthn_user_id if webauthn_user_id.present?

    # 新しいWebAuthn IDを生成
    new_id = SecureRandom.random_bytes(64)
    update!(webauthn_user_id: new_id)
    new_id
  end

  # 登録用のWebAuthnオプションを生成
  # @return [Hash] WebAuthn登録オプション
  def webauthn_registration_options
    WebauthnService.registration_options(self)
  end

  # 認証用のWebAuthnオプションを生成
  # @return [Hash] WebAuthn認証オプション
  def webauthn_authentication_options
    WebauthnService.authentication_options(self)
  end

  # WebAuthnクレデンシャルを登録
  # @param credential [WebAuthn::Credential] 検証済みクレデンシャル
  # @param nickname [String] クレデンシャルのニックネーム
  # @return [WebauthnCredential] 作成されたクレデンシャルレコード
  def register_webauthn_credential(credential, nickname: nil)
    WebauthnService.register_credential(self, credential, nickname)
  end

  # WebAuthn認証を検証
  # @param credential [WebAuthn::Credential] 認証レスポンス
  # @param challenge [String] チャレンジ文字列
  # @return [Boolean] 認証成功の場合true
  def verify_webauthn_authentication(credential, challenge)
    WebauthnService.verify_authentication(self, credential, challenge)
  end

  # Theme management methods

  # テーマ設定の表示名を取得
  # @return [String] テーマの日本語表示名
  def theme_display_name
    case theme_preference
    when "light"
      "ライトモード"
    when "dark"
      "ダークモード"
    when "system"
      "システム設定に従う"
    else
      "不明"
    end
  end

  # 利用可能なテーマオプションを取得
  # @return [Array<Array>] [[表示名, 値], ...] の配列
  def self.theme_options
    [
      [ "ライトモード", "light" ],
      [ "ダークモード", "dark" ],
      [ "システム設定に従う", "system" ]
    ]
  end

  # テーマ設定を更新
  # @param new_theme [String] 新しいテーマ設定
  # @return [Boolean] 更新成功の場合true
  def update_theme!(new_theme)
    if theme_preferences.key?(new_theme)
      update!(theme_preference: new_theme)
    else
      false
    end
  end

  # Devise session compatibility method for newer versions
  def self.serialize_from_session(key, salt = nil)
    find_by(id: key)
  end

  private

  # 強固なパスワード要求が有効かどうか
  def should_validate_strong_password?
    SystemSetting.get("security.require_strong_password", true) && !from_omniauth?
  end

  # パスワード強度バリデーション
  def password_strength
    return unless password.present?

    errors.add(:password, "は大文字を含む必要があります") unless password.match(/[A-Z]/)
    errors.add(:password, "は小文字を含む必要があります") unless password.match(/[a-z]/)
    errors.add(:password, "は数字を含む必要があります") unless password.match(/[0-9]/)
    errors.add(:password, "は特殊文字を含む必要があります") unless password.match(/[^A-Za-z0-9]/)
  end
end
