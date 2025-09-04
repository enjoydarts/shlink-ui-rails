require "faraday"
require "json"

module Shlink
  class Error < StandardError; end

  class Client
    def initialize(base_url: ENV["SHLINK_BASE_URL"], api_key: ENV["SHLINK_API_KEY"])
      @conn = Faraday.new(url: base_url) do |f|
        f.request :json            # リクエストをJSON化
        f.response :json, content_type: /\bjson$/  # レスポンスJSONを自動パース
        f.adapter Faraday.default_adapter
      end
      @api_key = api_key
    end

    def create_short_url(long_url, slug = nil)
      payload = { longUrl: long_url }
      payload[:customSlug] = slug if slug.to_s != ""

      res = @conn.post("/rest/v3/short-urls") do |req|
        req.headers["X-Api-Key"] = @api_key
        req.body = payload
      end

      case res.status
      when 200, 201
        res.body # => { "shortUrl" => "https://...", ... }
      else
        msg = res.body.is_a?(Hash) ? (res.body["detail"] || res.body["title"]) : res.body.to_s
        raise Shlink::Error, "Shlink API error (#{res.status}): #{msg}"
      end
    rescue Faraday::Error => e
      raise Shlink::Error, "HTTP error: #{e.message}"
    end
  end
end
