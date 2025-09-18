module Shlink
  class SetRedirectRulesService < BaseService
    def call(short_code:, redirect_rules:)
      Rails.logger.info "Setting redirect rules for #{short_code}"
      Rails.logger.info "Redirect rules data: #{redirect_rules.inspect}"

      # nullをJSONで正しく送信するため、明示的にto_jsonでシリアライズ
      payload = { redirectRules: redirect_rules }
      Rails.logger.info "Request payload: #{payload.to_json}"

      # matchKey: nil を matchKey: null として正しく送信
      serialized_payload = payload.to_json
      Rails.logger.info "Serialized payload: #{serialized_payload}"
      Rails.logger.info "Request URL: #{@base_url}/rest/v3/short-urls/#{short_code}/redirect-rules"

      response = make_request(short_code, payload)
      Rails.logger.info "Response status: #{response.status}"
      Rails.logger.info "Response body: #{response.body.inspect}"

      handle_response(response)
    rescue Faraday::Error => e
      raise Shlink::Error, "HTTP error: #{e.message}"
    end

    private

    def make_request(short_code, payload)
      conn.post("/rest/v3/short-urls/#{short_code}/redirect-rules") do |req|
        req.headers.merge!(api_headers)
        req.headers['Content-Type'] = 'application/json'
        req.body = payload.to_json
      end
    end
  end
end
