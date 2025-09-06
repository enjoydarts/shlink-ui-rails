module Shlink
  class SyncShortUrlsService
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def call
      list_service = Shlink::ListShortUrlsService.new
      page = 1
      total_synced = 0

      loop do
        response = list_service.call(page: page, items_per_page: 100)
        short_urls_data = response["shortUrls"]["data"]

        break if short_urls_data.empty?

        short_urls_data.each do |short_url_data|
          sync_short_url(short_url_data)
          total_synced += 1
        end

        # Check if we've reached the last page
        pagination = response["shortUrls"]["pagination"]
        break if pagination["currentPage"] >= pagination["pagesCount"]

        page += 1
      end

      total_synced
    rescue Shlink::Error => e
      Rails.logger.error "Failed to sync short URLs: #{e.message}"
      raise e
    end

    private

    def sync_short_url(data)
      short_url_attrs = extract_short_url_attributes(data)

      short_url = user.short_urls.find_or_initialize_by(short_code: short_url_attrs[:short_code])
      short_url.assign_attributes(short_url_attrs)

      if short_url.changed?
        short_url.save!
        Rails.logger.info "Synced short URL: #{short_url.short_code}"
      end
    end

    def extract_short_url_attributes(data)
      {
        short_code: data["shortCode"],
        short_url: data["shortUrl"],
        long_url: data["longUrl"],
        domain: data["domain"],
        title: data["title"],
        tags: data["tags"]&.to_json,
        meta: data["meta"]&.to_json,
        visit_count: data["visitsSummary"]&.dig("total") || 0,
        valid_since: parse_date(data["validSince"]),
        valid_until: parse_date(data["validUntil"]),
        max_visits: data["maxVisits"],
        crawlable: data["crawlable"] != false,
        forward_query: data["forwardQuery"] != false,
        date_created: parse_date(data["dateCreated"]) || Time.current
      }
    end

    def parse_date(date_string)
      return nil if date_string.blank?

      Time.zone.parse(date_string)
    rescue => e
      Rails.logger.warn "Failed to parse date: #{date_string} - #{e.message}"
      nil
    end
  end
end
