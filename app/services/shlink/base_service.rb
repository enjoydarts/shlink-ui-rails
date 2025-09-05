require "faraday"
require "json"

module Shlink
  class Error < StandardError; end

  class BaseService
    attr_reader :base_url, :api_key, :conn

    def initialize(base_url: ENV["SHLINK_BASE_URL"], api_key: ENV["SHLINK_API_KEY"])
      @base_url = base_url
      @api_key = api_key
      @conn = build_connection
    end

    private

    def build_connection
      Faraday.new(url: base_url) do |f|
        f.request :json
        f.response :json, content_type: /\bjson$/
        f.adapter Faraday.default_adapter
      end
    end

    def handle_response(response)
      case response.status
      when 200, 201
        response.body
      else
        error_message = extract_error_message(response.body)
        raise Shlink::Error, "Shlink API error (#{response.status}): #{error_message}"
      end
    end

    def extract_error_message(body)
      return body.to_s unless body.is_a?(Hash)
      body["detail"] || body["title"] || body.to_s
    end

    def api_headers
      { "X-Api-Key" => api_key }
    end
  end
end
