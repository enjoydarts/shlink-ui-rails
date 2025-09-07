module Shlink
  class CreateShortUrlService < BaseService
    def call(long_url:, slug: nil, valid_until: nil, max_visits: nil, tags: [])
      payload = build_payload(long_url, slug, valid_until, max_visits, tags)
      response = make_request(payload)
      handle_response(response)
    rescue Faraday::Error => e
      raise Shlink::Error, "HTTP error: #{e.message}"
    end

    def call!(long_url:, slug: nil, valid_until: nil, max_visits: nil, tags: [])
      call(long_url: long_url, slug: slug, valid_until: valid_until, max_visits: max_visits, tags: tags)
    end

    private

    def build_payload(long_url, slug, valid_until, max_visits, tags)
      payload = { longUrl: long_url }
      payload[:customSlug] = slug if slug.to_s != ""
      payload[:validUntil] = valid_until.iso8601 if valid_until.present?
      payload[:maxVisits] = max_visits if max_visits.present?
      payload[:tags] = tags if tags.present? && tags.any?
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
