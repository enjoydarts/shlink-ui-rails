module TwoFactorHelpers
  def enable_2fa_for(user)
    user.update!(
      otp_secret_key: ROTP::Base32.random_base32,
      otp_required_for_login: true
    )
  end

  def valid_otp_token(user)
    ROTP::TOTP.new(user.otp_secret_key).now
  end

  def invalid_otp_token
    "000000"
  end
end

RSpec.configure do |config|
  config.include TwoFactorHelpers
end
