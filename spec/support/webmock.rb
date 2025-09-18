require 'webmock/rspec'

RSpec.configure do |config|
  config.before(:each) do
    WebMock.reset!
    WebMock.disable_net_connect!(allow_localhost: true)

    # ConfigShortcutsのShlink設定をテスト用にスタブ
    allow_any_instance_of(Shlink::BaseService).to receive(:shlink_base_url).and_return('https://test.example.com')
    allow_any_instance_of(Shlink::BaseService).to receive(:shlink_api_key).and_return('test-api-key')

    # ShortUrlモデルのredirect rules同期をモック
    allow_any_instance_of(ShortUrl).to receive(:sync_redirect_rules_from_api).and_return([])

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

    # Shlink API health check (used in admin dashboard)
    WebMock.stub_request(:get, "#{Settings.shlink.base_url}/rest/health")
      .with(headers: { "X-Api-Key" => Settings.shlink.api_key })
      .to_return(
        status: 200,
        body: { status: "pass", version: "3.0.0" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # CAPTCHA verification requests
    WebMock.stub_request(:post, "https://challenges.cloudflare.com/turnstile/v0/siteverify")
      .to_return(
        status: 200,
        body: { success: true }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Shlink API short URLs listing - 任意のbase URLに対応
    WebMock.stub_request(:get, /\/rest\/v\d+\/short-urls/)
      .to_return(
        status: 200,
        body: {
          shortUrls: {
            data: [],
            pagination: {
              currentPage: 1,
              pagesCount: 1,
              itemsPerPage: 10,
              itemsInCurrentPage: 0,
              totalItems: 0
            }
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Shlink API short URL creation
    WebMock.stub_request(:post, "#{Settings.shlink.base_url}/rest/v3/short-urls")
      .with(headers: { "X-Api-Key" => Settings.shlink.api_key })
      .to_return(
        status: 200,
        body: {
          shortCode: "abc123",
          shortUrl: "https://s.test/abc123",
          longUrl: "https://example.com"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Shlink API individual short URL details
    WebMock.stub_request(:get, /#{Regexp.escape(Settings.shlink.base_url)}\/rest\/v\d+\/short-urls\/[^\/]+$/)
      .with(headers: { "X-Api-Key" => Settings.shlink.api_key })
      .to_return(
        status: 200,
        body: {
          shortCode: "abc123",
          shortUrl: "https://s.test/abc123",
          longUrl: "https://example.com"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Shlink API short URL deletion
    WebMock.stub_request(:delete, /#{Regexp.escape(Settings.shlink.base_url)}\/rest\/v\d+\/short-urls\//)
      .with(headers: { "X-Api-Key" => Settings.shlink.api_key })
      .to_return(status: 204)

    # Shlink API individual short URL stats
    WebMock.stub_request(:get, /#{Regexp.escape(Settings.shlink.base_url)}\/rest\/v\d+\/short-urls\/[^\/]+\/visits/)
      .with(headers: { "X-Api-Key" => Settings.shlink.api_key })
      .to_return(
        status: 200,
        body: {
          visits: {
            data: [],
            pagination: {
              currentPage: 1,
              pagesCount: 1,
              itemsPerPage: 50,
              itemsInCurrentPage: 0,
              totalItems: 0
            }
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Shlink API redirect rules - 任意のbase URLに対応
    WebMock.stub_request(:get, %r{https://[^/]+/rest/v\d+/short-urls/[^/]+/redirect-rules})
      .to_return(
        status: 200,
        body: {
          defaultLongUrl: "https://example.com",
          redirectRules: []
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Shlink API redirect rules setting - 任意のbase URLに対応
    WebMock.stub_request(:post, %r{https://[^/]+/rest/v\d+/short-urls/[^/]+/redirect-rules})
      .to_return(
        status: 200,
        body: {
          defaultLongUrl: "https://example.com",
          redirectRules: []
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end
