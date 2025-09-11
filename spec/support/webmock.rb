require 'webmock/rspec'

RSpec.configure do |config|
  config.before(:each) do
    WebMock.reset!
    WebMock.disable_net_connect!(allow_localhost: true)

    # Google OAuth APIをスタブ
    WebMock.stub_request(:post, "https://oauth2.googleapis.com/token")
      .to_return(status: 200, body: {
        access_token: "fake_access_token",
        token_type: "Bearer",
        expires_in: 3600
      }.to_json, headers: { 'Content-Type' => 'application/json' })

    WebMock.stub_request(:get, "https://www.googleapis.com/oauth2/v2/userinfo")
      .to_return(status: 200, body: {
        id: "123456789",
        email: "test@example.com",
        name: "Test User",
        picture: "https://example.com/avatar.jpg"
      }.to_json, headers: { 'Content-Type' => 'application/json' })
  end
end
