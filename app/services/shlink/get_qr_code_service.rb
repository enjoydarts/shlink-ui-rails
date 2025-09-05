module Shlink
  class GetQrCodeService < BaseService
    def call(short_code:, size: 300, format: "png", margin: nil)
      options = { size: size, format: format }
      options[:margin] = margin if margin

      primary_response = try_primary_endpoint(short_code, options)
      return primary_response if primary_response

      fallback_response = try_fallback_endpoint(short_code, options)
      return fallback_response if fallback_response

      raise Shlink::Error, "QR Code API error: Unable to retrieve QR code"
    rescue Faraday::Error => e
      raise Shlink::Error, "HTTP error: #{e.message}"
    end

    def call!(short_code:, size: 300, format: "png", margin: nil)
      call(short_code: short_code, size: size, format: format, margin: margin)
    end

    private

    def try_primary_endpoint(short_code, options)
      url = build_url("/#{short_code}/qr-code", options)
      response = make_qr_request(url)
      return build_qr_response(response, options[:format]) if response.status == 200
      nil
    end

    def try_fallback_endpoint(short_code, options)
      url = build_url("/rest/v3/short-urls/#{short_code}/qr-code", options)
      response = make_qr_request(url)
      return build_qr_response(response, options[:format]) if response.status == 200
      nil
    end

    def build_url(path, options)
      query_string = options.compact.map { |k, v| "#{k}=#{v}" }.join("&")
      query_string.empty? ? path : "#{path}?#{query_string}"
    end

    def make_qr_request(url)
      conn.get(url) do |req|
        req.headers.merge!(api_headers)
      end
    end

    def build_qr_response(response, format)
      {
        content_type: response.headers["content-type"],
        data: response.body,
        format: format
      }
    end
  end
end
