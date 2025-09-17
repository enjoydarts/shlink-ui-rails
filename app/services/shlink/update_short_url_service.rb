module Shlink
  class UpdateShortUrlService < BaseService
    # 短縮URLを更新する
    # @param short_code [String] 短縮URLコード
    # @param title [String, nil] タイトル
    # @param long_url [String, nil] 元のURL
    # @param tags [Array<String>, nil] タグ配列
    # @param valid_until [DateTime, nil] 有効期限
    # @param max_visits [Integer, nil] 最大訪問数
    # @param custom_slug [String, nil] カスタムスラッグ
    # @return [Hash] Shlink APIからのレスポンス
    def call(short_code:, title: nil, long_url: nil, tags: nil, valid_until: nil, max_visits: nil, custom_slug: nil)
      payload = build_payload(title, long_url, tags, valid_until, max_visits, custom_slug)
      response = make_request(short_code, payload)
      handle_response(response)
    rescue Faraday::Error => e
      raise Shlink::Error, "HTTP error: #{e.message}"
    end

    private

    def build_payload(title, long_url, tags, valid_until, max_visits, custom_slug)
      payload = {}

      # タイトル
      payload[:title] = title if title.present?

      # 元のURL
      payload[:longUrl] = long_url if long_url.present?

      # タグ
      payload[:tags] = tags if tags.present? && tags.any?

      # 有効期限
      if valid_until.present?
        payload[:validUntil] = valid_until.iso8601
      elsif valid_until == ""
        # 空文字列の場合は有効期限を削除
        payload[:validUntil] = nil
      end

      # 最大訪問数
      if max_visits.present?
        payload[:maxVisits] = max_visits
      elsif max_visits == ""
        # 空文字列の場合は訪問制限を削除
        payload[:maxVisits] = nil
      end

      # カスタムスラッグ
      payload[:customSlug] = custom_slug if custom_slug.present?

      payload
    end

    def make_request(short_code, payload)
      conn.patch("/rest/v3/short-urls/#{short_code}") do |req|
        req.headers.merge!(api_headers)
        req.body = payload
      end
    end
  end
end
