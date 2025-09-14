require 'rails_helper'

RSpec.describe "Rate Limiting", type: :request do
  before do
    # Enable rate limiting for tests
    setting = SystemSetting.find_or_initialize_by(key_name: 'rate_limit.enabled')
    setting.assign_attributes(
      value: 'true',
      setting_type: 'boolean',
      category: 'rate_limit'
    )
    setting.save!
  end

  after do
    # Clean up cache to reset rate limits
    Rails.cache.clear
    Rack::Attack.cache.store.clear if Rack::Attack.cache.store.respond_to?(:clear)
  end

  describe "Web requests rate limiting" do
    it "allows requests within limit" do
      get root_path
      expect(response).to have_http_status(:ok)
    end

    it "blocks requests exceeding limit", :skip_ci do
      # Clear rate limiting cache before test
      Rails.cache.clear
      Rack::Attack.cache.store.clear if Rack::Attack.cache.store.respond_to?(:clear)

      # Set a very low limit for testing
      setting = SystemSetting.find_or_initialize_by(key_name: 'rate_limit.web_requests_per_minute')
      setting.assign_attributes(
        value: '2',
        setting_type: 'integer',
        category: 'rate_limit',
        enabled: true
      )
      setting.save!

      # Make requests up to the limit
      2.times do
        get root_path
        expect(response).to have_http_status(:ok)
      end

      # Next request should be blocked
      get root_path
      expect(response).to have_http_status(:too_many_requests)

      # Web requests return HTML, not JSON
      expect(response.body).to include('Too Many Requests')
    end
  end

  describe "Login attempts rate limiting" do
    it "blocks excessive login attempts", :skip_ci do
      # Clear rate limiting cache before test
      Rails.cache.clear
      Rack::Attack.cache.store.clear if Rack::Attack.cache.store.respond_to?(:clear)

      # Set a very low limit for testing
      setting = SystemSetting.find_or_initialize_by(key_name: 'rate_limit.login_attempts_per_hour')
      setting.assign_attributes(
        value: '2',
        setting_type: 'integer',
        category: 'rate_limit',
        enabled: true
      )
      setting.save!

      # Make login attempts up to the limit
      2.times do
        post user_session_path, params: {
          user: { email: 'test@example.com', password: 'wrongpassword' }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      # Next attempt should be blocked
      post user_session_path, params: {
        user: { email: 'test@example.com', password: 'wrongpassword' }
      }
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "Rate limiting disabled" do
    before do
      SystemSetting.find_by(key_name: 'rate_limit.enabled')&.update!(value: 'false')
    end

    it "allows unlimited requests when disabled" do
      # Make many requests - should all succeed
      10.times do
        get root_path
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
