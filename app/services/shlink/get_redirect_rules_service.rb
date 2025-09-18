module Shlink
  class GetRedirectRulesService < BaseService
    def call(short_code:)
      Rails.logger.info "Getting redirect rules for #{short_code}"
      Rails.logger.info "Request URL: #{@base_url}/rest/v3/short-urls/#{short_code}/redirect-rules"

      response = make_request(short_code)
      Rails.logger.info "Response status: #{response.status}"
      Rails.logger.info "Response body: #{response.body.inspect}"

      handle_response(response)
    rescue Faraday::Error => e
      raise Shlink::Error, "HTTP error: #{e.message}"
    end

    private

    def make_request(short_code)
      conn.get("/rest/v3/short-urls/#{short_code}/redirect-rules") do |req|
        req.headers.merge!(api_headers)
      end
    end
  end
end