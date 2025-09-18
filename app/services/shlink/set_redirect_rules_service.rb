module Shlink
  class SetRedirectRulesService < BaseService
    def call(short_code:, redirect_rules:)
      payload = { redirectRules: redirect_rules }
      response = make_request(short_code, payload)
      handle_response(response)
    rescue Faraday::Error => e
      raise Shlink::Error, "HTTP error: #{e.message}"
    end

    private

    def make_request(short_code, payload)
      conn.post("/rest/v3/short-urls/#{short_code}/redirect-rules") do |req|
        req.headers.merge!(api_headers)
        req.body = payload
      end
    end
  end
end
