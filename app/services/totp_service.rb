# frozen_string_literal: true

class TotpService
  include ActiveModel::Model
  include ActiveModel::Attributes

  # バックアップコード関連の定数
  BACKUP_CODE_COUNT = 8
  BACKUP_CODE_LENGTH = 8

  attr_accessor :user

  validates :user, presence: true

  # TOTP秘密鍵を生成してユーザーに設定
  # @param user [User] 対象ユーザー
  # @return [String] Base32エンコードされた秘密鍵
  def self.generate_secret_for(user)
    service = new(user: user)
    service.generate_secret
  end

  # QRコードを生成
  # @param user [User] 対象ユーザー
  # @param issuer [String] 発行者名（アプリ名）
  # @return [String] QRコードのSVG文字列
  def self.generate_qr_code(user, issuer: "Shlink-UI-Rails")
    service = new(user: user)
    service.generate_qr_code(issuer: issuer)
  end

  # TOTPコードを検証
  # @param user [User] 対象ユーザー
  # @param code [String] 6桁のTOTPコード
  # @param drift [Integer] 時間のドリフト許容範囲（秒）
  # @return [Boolean] 検証成功の場合true
  def self.verify_code(user, code, drift: 30)
    service = new(user: user)
    service.verify_code(code, drift: drift)
  end

  # バックアップコードを生成
  # @param user [User] 対象ユーザー
  # @return [Array<String>] バックアップコード配列
  def self.generate_backup_codes(user)
    service = new(user: user)
    service.generate_backup_codes
  end

  # バックアップコードを検証・使用
  # @param user [User] 対象ユーザー
  # @param code [String] バックアップコード
  # @return [Boolean] 検証成功の場合true
  def self.verify_backup_code(user, code)
    service = new(user: user)
    service.verify_backup_code(code)
  end

  # 2FA有効化
  # @param user [User] 対象ユーザー
  # @param verification_code [String] 検証用TOTPコード
  # @return [Boolean] 有効化成功の場合true
  def self.enable_for(user, verification_code)
    service = new(user: user)
    service.enable_two_factor(verification_code)
  end

  # 2FA無効化
  # @param user [User] 対象ユーザー
  # @return [Boolean] 無効化成功の場合true
  def self.disable_for(user)
    service = new(user: user)
    service.disable_two_factor
  end

  # ユーザーのシークレットキーを取得
  # @param user [User] 対象ユーザー
  # @return [String] Base32エンコードされたシークレットキー
  def self.get_secret(user)
    service = new(user: user)
    service.get_secret
  end

  # インスタンスメソッド

  # 新しい秘密鍵を生成
  # @return [String] Base32エンコードされた秘密鍵
  def generate_secret
    return nil unless valid?

    secret = ROTP::Base32.random
    user.otp_secret_key = encrypt_secret(secret)
    user.save! # 秘密鍵を保存
    secret
  end

  # QRコードのSVG文字列を生成
  # @param issuer [String] 発行者名
  # @return [String] QRコードのSVG文字列
  def generate_qr_code(issuer: "Shlink-UI-Rails")
    return nil unless valid? && user.otp_secret_key.present?

    secret = decrypt_secret(user.otp_secret_key)
    return nil if secret.blank?

    totp = ROTP::TOTP.new(secret, issuer: issuer)
    provisioning_uri = totp.provisioning_uri(user.email)

    qr_code = RQRCode::QRCode.new(provisioning_uri)
    qr_code.as_svg(
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 3,
      standalone: true,
      use_path: true
    )
  rescue StandardError => e
    Rails.logger.error "QR code generation failed: #{e.message}"
    nil
  end

  # TOTPコードを検証
  # @param code [String] 6桁のTOTPコード
  # @param drift [Integer] 時間のドリフト許容範囲（秒）
  # @return [Boolean] 検証成功の場合true
  def verify_code(code, drift: 30)
    return false unless valid? && user.otp_secret_key.present?
    return false if code.blank?

    secret = decrypt_secret(user.otp_secret_key)
    return false if secret.blank?

    totp = ROTP::TOTP.new(secret)
    totp.verify(code, drift_behind: drift, drift_ahead: drift).present?
  rescue StandardError => e
    Rails.logger.error "TOTP verification failed: #{e.message}"
    false
  end

  # バックアップコードを生成
  # @return [Array<String>] バックアップコード配列
  def generate_backup_codes
    return [] unless valid?

    codes = Array.new(BACKUP_CODE_COUNT) { generate_backup_code }
    encrypted_codes = encrypt_backup_codes(codes)

    user.otp_backup_codes = encrypted_codes
    user.otp_backup_codes_generated_at = Time.current

    codes
  end

  # バックアップコードを検証・使用
  # @param code [String] バックアップコード
  # @return [Boolean] 検証成功の場合true
  def verify_backup_code(code)
    return false unless valid? && user.otp_backup_codes.present?
    return false if code.blank?

    backup_codes = decrypt_backup_codes(user.otp_backup_codes)
    return false if backup_codes.blank?

    normalized_code = code.gsub(/\s|-/, "").downcase
    matching_code = backup_codes.find { |bc| bc == normalized_code }

    return false unless matching_code

    # 使用済みコードを削除
    backup_codes.delete(matching_code)
    user.otp_backup_codes = encrypt_backup_codes(backup_codes)
    user.save!

    true
  rescue StandardError => e
    Rails.logger.error "Backup code verification failed: #{e.message}"
    false
  end

  # 2FA有効化
  # @param verification_code [String] 検証用TOTPコード
  # @return [Boolean] 有効化成功の場合true
  def enable_two_factor(verification_code)
    return false unless valid?
    return false unless verify_code(verification_code)

    user.otp_required_for_login = true
    # バックアップコードを確実に生成
    if user.otp_backup_codes.blank?
      Rails.logger.info "Generating backup codes for user #{user.id}"
      backup_codes = generate_backup_codes
      Rails.logger.info "Generated #{backup_codes.size} backup codes"
    end

    user.save!
    true
  rescue StandardError => e
    Rails.logger.error "2FA enablement failed: #{e.message}"
    false
  end

  # 2FA無効化
  # @return [Boolean] 無効化成功の場合true
  def disable_two_factor
    return false unless valid?

    user.otp_required_for_login = false
    user.otp_secret_key = nil
    user.otp_backup_codes = nil
    user.otp_backup_codes_generated_at = nil

    user.save!
  rescue StandardError => e
    Rails.logger.error "2FA disabling failed: #{e.message}"
    false
  end

  # ユーザーのシークレットキーを取得（なければ生成）
  # @return [String] Base32エンコードされたシークレットキー
  def get_secret
    return nil unless valid?

    if user.otp_secret_key.present?
      decrypt_secret(user.otp_secret_key)
    else
      generate_secret
    end
  end

  private

  # 秘密鍵を暗号化
  # @param secret [String] 平文の秘密鍵
  # @return [String] 暗号化された秘密鍵
  def encrypt_secret(secret)
    return nil if secret.blank?

    Rails.application.message_verifier(:otp_secret).generate(secret)
  end

  # 秘密鍵を復号化
  # @param encrypted_secret [String] 暗号化された秘密鍵
  # @return [String] 平文の秘密鍵
  def decrypt_secret(encrypted_secret)
    return nil if encrypted_secret.blank?

    Rails.application.message_verifier(:otp_secret).verify(encrypted_secret)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    Rails.logger.error "Invalid OTP secret signature"
    nil
  end

  # バックアップコードを暗号化してJSON形式で保存
  # @param codes [Array<String>] バックアップコード配列
  # @return [String] 暗号化されたJSONデータ
  def encrypt_backup_codes(codes)
    return nil if codes.blank?

    Rails.application.message_verifier(:backup_codes).generate(codes.to_json)
  end

  # バックアップコードを復号化
  # @param encrypted_codes [String] 暗号化されたJSONデータ
  # @return [Array<String>] バックアップコード配列
  def decrypt_backup_codes(encrypted_codes)
    return [] if encrypted_codes.blank?

    json_data = Rails.application.message_verifier(:backup_codes).verify(encrypted_codes)
    JSON.parse(json_data)
  rescue ActiveSupport::MessageVerifier::InvalidSignature, JSON::ParserError
    Rails.logger.error "Invalid backup codes signature or JSON"
    []
  end

  # 単一のバックアップコードを生成
  # @return [String] 8文字のランダムコード
  def generate_backup_code
    SecureRandom.alphanumeric(BACKUP_CODE_LENGTH).downcase
  end
end
