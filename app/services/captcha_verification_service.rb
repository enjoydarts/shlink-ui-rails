# frozen_string_literal: true

class CaptchaVerificationService
  include ActiveModel::Model
  include ActiveModel::Attributes

  # Cloudflare Turnstile検証結果の構造体
  Result = Struct.new(:success, :error_codes, :challenge_ts, :hostname, keyword_init: true) do
    def success?
      success == true
    end

    def failed?
      !success?
    end
  end

  attr_accessor :token, :remote_ip

  validates :token, presence: true

  # CAPTCHA検証のメインメソッド
  # @param token [String] フロントエンドから受信したTurnstileトークン
  # @param remote_ip [String] クライアントのIPアドレス（オプション）
  # @return [CaptchaVerificationService::Result] 検証結果
  def self.verify(token:, remote_ip: nil)
    service = new(token: token, remote_ip: remote_ip)
    service.verify
  end

  # 検証実行
  # @return [CaptchaVerificationService::Result] 検証結果
  def verify
    return failed_result([ "missing-input-response" ]) unless valid?
    return disabled_result if captcha_disabled?

    perform_verification
  rescue Faraday::TimeoutError
    failed_result([ "timeout" ])
  rescue Faraday::Error => e
    Rails.logger.error "CAPTCHA verification failed: #{e.message}"
    failed_result([ "network-error" ])
  end

  private

  # 実際のTurnstile API呼び出し
  # @return [CaptchaVerificationService::Result] 検証結果
  def perform_verification
    response = http_client.post(verify_url, verification_params)
    parse_response(response)
  end

  # API レスポンスのパース
  # @param response [Faraday::Response] HTTPレスポンス
  # @return [CaptchaVerificationService::Result] 検証結果
  def parse_response(response)
    return failed_result([ "invalid-response" ]) unless response.success?

    body = JSON.parse(response.body)
    Result.new(
      success: body["success"],
      error_codes: body["error-codes"] || [],
      challenge_ts: body["challenge_ts"],
      hostname: body["hostname"]
    )
  rescue JSON::ParserError
    failed_result([ "invalid-json" ])
  end

  # HTTPクライアントの設定
  # @return [Faraday::Connection] HTTPクライアント
  def http_client
    @http_client ||= Faraday.new do |faraday|
      faraday.request :url_encoded
      faraday.adapter Faraday.default_adapter
      faraday.options.timeout = Settings.captcha.turnstile.timeout
    end
  end

  # 検証用パラメータの構築
  # @return [Hash] APIリクエストパラメータ
  def verification_params
    params = {
      secret: Settings.captcha.turnstile.secret_key,
      response: token
    }
    params[:remoteip] = remote_ip if remote_ip.present?
    params
  end

  # 検証失敗時の結果
  # @param error_codes [Array<String>] エラーコード配列
  # @return [CaptchaVerificationService::Result] 失敗結果
  def failed_result(error_codes)
    Result.new(success: false, error_codes: error_codes)
  end

  # CAPTCHA無効時の結果（開発・テスト環境用）
  # @return [CaptchaVerificationService::Result] 成功結果
  def disabled_result
    Rails.logger.debug "CAPTCHA verification skipped (disabled)"
    Result.new(success: true, error_codes: [])
  end

  # CAPTCHA機能の有効/無効判定
  # @return [Boolean] 無効の場合true
  def captcha_disabled?
    CaptchaHelper.disabled?
  end

  # 検証API URL
  # @return [String] Turnstile検証エンドポイント
  def verify_url
    Settings.captcha.turnstile.verify_url
  end
end
