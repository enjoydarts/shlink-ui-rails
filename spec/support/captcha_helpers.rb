module CaptchaHelpers
  def mock_captcha_success
    success_result = CaptchaVerificationService::Result.new(
      success: true,
      error_codes: [],
      challenge_ts: Time.current.to_s,
      hostname: "test.local"
    )
    allow(CaptchaVerificationService).to receive(:verify).and_return(success_result)
  end

  def mock_captcha_failure
    failure_result = CaptchaVerificationService::Result.new(
      success: false,
      error_codes: [ "invalid-input-response" ],
      challenge_ts: nil,
      hostname: nil
    )
    allow(CaptchaVerificationService).to receive(:verify).and_return(failure_result)
  end
end

RSpec.configure do |config|
  config.include CaptchaHelpers

  # By default, mock CAPTCHA as successful for all tests
  config.before(:each) do
    mock_captcha_success
  end
end
