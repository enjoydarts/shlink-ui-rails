# Rack::Attack configuration for rate limiting
# This configuration dynamically reads settings from SystemSetting

# Configure Rack::Attack cache store
if Rails.env.test?
  # Use memory store for tests to avoid Redis dependency
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
else
  # Use Redis for development and production
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(
    url: Settings.redis.url,
    timeout: Settings.redis.timeout,
    pool: {
      size: Settings.redis.pool_size,
      timeout: Settings.redis.pool_timeout
    }
  )
end

class Rack::Attack
  # Enable/disable rate limiting based on SystemSetting
  def self.enabled?
    return false unless defined?(SystemSetting)

    begin
      # In test environment, only enable if explicitly configured
      if Rails.env.test?
        SystemSetting.get("rate_limit.enabled", false)
      else
        SystemSetting.get("rate_limit.enabled", true)
      end
    rescue => e
      Rails.logger.error "Failed to check rate_limit.enabled setting: #{e.message}"
      false
    end
  end

  # Skip rate limiting if disabled
  safelist("allow when disabled") do |req|
    !Rack::Attack.enabled?
  end

  # Helper method to get rate limit settings
  def self.rate_limit_setting(key, default)
    return default unless enabled?

    begin
      setting_value = SystemSetting.get(key, default)
      # Convert string values to integers for limits
      if setting_value.is_a?(String) && setting_value =~ /^\d+$/
        setting_value.to_i
      else
        setting_value
      end
    rescue => e
      Rails.logger.error "Failed to get rate limit setting #{key}: #{e.message}"
      default
    end
  end

  # API requests rate limiting
  throttle("api/requests", limit: proc { rate_limit_setting("rate_limit.api_requests_per_minute", 60) }, period: 1.minute) do |req|
    if req.path.start_with?("/api/")
      req.ip
    end
  end

  # Web requests rate limiting
  throttle("web/requests", limit: proc { rate_limit_setting("rate_limit.web_requests_per_minute", 120) }, period: 1.minute) do |req|
    unless req.path.start_with?("/api/")
      req.ip
    end
  end

  # URL creation rate limiting
  throttle("url_creation", limit: proc { rate_limit_setting("rate_limit.url_creation_per_hour", 100) }, period: 1.hour) do |req|
    if req.path == "/short_urls" && req.post?
      req.ip
    end
  end

  # Login attempts rate limiting (IP-based, works with Devise lockable)
  throttle("login/attempts", limit: proc { rate_limit_setting("rate_limit.login_attempts_per_hour", 10) }, period: 1.hour) do |req|
    if req.path == "/users/sign_in" && req.post?
      req.ip
    end
  end

  # Failed login attempts rate limiting (email-based to complement Devise lockable)
  throttle("login/email", limit: proc { rate_limit_setting("rate_limit.login_attempts_per_hour", 10) }, period: 1.hour) do |req|
    if req.path == "/users/sign_in" && req.post?
      # Extract email from request parameters
      email = req.params["user"] && req.params["user"]["email"]
      email.present? ? email.downcase.strip : nil
    end
  end

  # Custom response for throttled requests
  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = match_data[:epoch_time]

    headers = {
      "X-RateLimit-Limit" => match_data[:limit].to_s,
      "X-RateLimit-Remaining" => "0",
      "X-RateLimit-Reset" => (now + (match_data[:period] - now % match_data[:period])).to_s,
      "Retry-After" => match_data[:period].to_s
    }

    error_message = case request.env["rack.attack.matched"]
    when "api/requests"
      "API rate limit exceeded. Please try again later."
    when "web/requests"
      "Request rate limit exceeded. Please try again later."
    when "url_creation"
      "URL creation rate limit exceeded. Please try again later."
    when "login/attempts"
      "Login attempt rate limit exceeded. Please try again later."
    else
      "Rate limit exceeded. Please try again later."
    end

    # APIリクエストの場合はJSONレスポンス、Webリクエストの場合はHTMLページ
    if request.path.start_with?("/api/") || request.env["HTTP_ACCEPT"]&.include?("application/json")
      headers["Content-Type"] = "application/json"
      body = {
        error: "Rate Limit Exceeded",
        message: error_message,
        retry_after: match_data[:period]
      }.to_json
    else
      # WebリクエストにはHTMLページを返す
      headers["Content-Type"] = "text/html"
      begin
        body = File.read(Rails.public_path.join("429.html"))
      rescue => e
        # フォールバック: シンプルなHTMLレスポンス
        body = <<~HTML
          <!DOCTYPE html>
          <html><head><title>429 Too Many Requests</title></head>
          <body><h1>Too Many Requests</h1><p>#{error_message}</p></body></html>
        HTML
      end
    end

    [ 429, headers, [ body ] ]
  end

  # Log blocked requests
  ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
    request = payload[:request]

    case request.env["rack.attack.match_type"]
    when :throttle
      Rails.logger.warn "Rate limit exceeded for IP #{request.ip}: #{request.env['rack.attack.matched']}"
    end
  end
end
