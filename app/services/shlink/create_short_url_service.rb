module Shlink
  class CreateShortUrlService < BaseService
    def call(long_url:, slug: nil)
      payload = build_payload(long_url, slug)
      response = make_request(payload)
      handle_response(response)
    rescue Faraday::Error => e
      raise Shlink::Error, "HTTP error: #{e.message}"
    end

    def call!(long_url:, slug: nil)
      call(long_url: long_url, slug: slug)
    end

    private

    def build_payload(long_url, slug)
      payload = { longUrl: long_url }
      payload[:customSlug] = slug if slug.to_s != ""
      payload
    end

    def make_request(payload)
      conn.post("/rest/v3/short-urls") do |req|
        req.headers.merge!(api_headers)
        req.body = payload
      end
    end
  end
end