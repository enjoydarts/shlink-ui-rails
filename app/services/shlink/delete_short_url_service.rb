module Shlink
  class DeleteShortUrlService < BaseService
    def initialize(short_code)
      super()
      @short_code = short_code
    end

    def call
      response = conn.delete(delete_url, nil, api_headers)

      if response.success?
        Rails.logger.info "Successfully deleted short URL: #{@short_code}"
        true
      else
        error_message = parse_error_message(response)
        Rails.logger.error "Failed to delete short URL #{@short_code}: #{error_message}"
        raise Shlink::Error.new(error_message)
      end
    rescue Faraday::Error => e
      Rails.logger.error "Network error deleting short URL #{@short_code}: #{e.message}"
      raise Shlink::Error.new("ネットワークエラーが発生しました: #{e.message}")
    end

    def call!
      call
    rescue Shlink::Error => e
      raise e
    end

    private

    attr_reader :short_code

    def delete_url
      "/rest/v3/short-urls/#{short_code}"
    end

    def parse_error_message(response)
      error_data = response.body.is_a?(Hash) ? response.body : {}

      case response.status
      when 404
        "短縮URLが見つかりません"
      when 422
        "この短縮URLは削除できません"
      else
        error_data.dig("detail") || error_data.dig("title") || "不明なエラーが発生しました"
      end
    end
  end
end
