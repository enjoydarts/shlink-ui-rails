module Shlink
  class SyncShortUrlsService
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def call
      # ユーザーが既に持っているアクティブな短縮URLのみを同期
      # 新しいURLの発見ではなく、既存URLの統計情報更新に限定
      existing_short_codes = user.short_urls.active.pluck(:short_code)

      if existing_short_codes.empty?
        Rails.logger.info "User #{user.id} has no existing active short URLs to sync"
        return 0
      end

      total_synced = 0
      list_service = Shlink::ListShortUrlsService.new

      # APIから全URLを取得して、存在しないものをソフト削除
      api_short_codes = fetch_all_api_short_codes(list_service)

      # 既存の短縮URLの情報を個別に更新
      existing_short_codes.each do |short_code|
        begin
          if api_short_codes.include?(short_code)
            # API側に存在する場合は統計情報を更新
            updated = sync_existing_short_url(short_code, list_service)
            total_synced += 1 if updated
          else
            # API側に存在しない場合はソフト削除
            soft_delete_missing_url(short_code)
            Rails.logger.info "Soft deleted missing short URL: #{short_code} for user #{user.id}"
          end
        rescue => e
          Rails.logger.warn "Failed to sync short URL #{short_code} for user #{user.id}: #{e.message}"
          # 個別エラーは続行
        end
      end

      total_synced
    rescue Shlink::Error => e
      Rails.logger.error "Failed to sync short URLs for user #{user.id}: #{e.message}"
      raise e
    end

    private

    def fetch_all_api_short_codes(list_service)
      api_short_codes = []
      page = 1

      loop do
        response = list_service.call(page: page, items_per_page: 100)
        short_urls_data = response["shortUrls"]["data"]

        break if short_urls_data.empty?

        api_short_codes.concat(short_urls_data.map { |url_data| url_data["shortCode"] })

        # ページネーション確認
        pagination = response["shortUrls"]["pagination"]
        break if pagination["currentPage"] >= pagination["pagesCount"]

        page += 1
      end

      api_short_codes
    end

    def soft_delete_missing_url(short_code)
      short_url = user.short_urls.active.find_by(short_code: short_code)
      return unless short_url

      short_url.soft_delete!
    end

    def sync_existing_short_url(short_code, list_service)
      # Shlink APIから該当する短縮URLの情報を検索
      # 注意: これは非効率的な実装（全URL取得して検索）
      # 本来はShlink APIに個別URL取得エンドポイントが必要

      page = 1
      found_url_data = nil

      loop do
        response = list_service.call(page: page, items_per_page: 100)
        short_urls_data = response["shortUrls"]["data"]

        break if short_urls_data.empty?

        # 該当するshort_codeを探す
        found_url_data = short_urls_data.find { |url_data| url_data["shortCode"] == short_code }
        break if found_url_data

        # ページネーション確認
        pagination = response["shortUrls"]["pagination"]
        break if pagination["currentPage"] >= pagination["pagesCount"]

        page += 1
      end

      if found_url_data
        sync_short_url(found_url_data)
        true
      else
        Rails.logger.warn "Short URL #{short_code} not found in Shlink API for user #{user.id}"
        false
      end
    end

    def sync_short_url(data)
      short_url_attrs = extract_short_url_attributes(data)

      # セキュリティチェック: 既にこのユーザーが所有しているURLのみ更新
      short_url = user.short_urls.find_by(short_code: short_url_attrs[:short_code])

      unless short_url
        Rails.logger.error "Attempted to sync URL #{short_url_attrs[:short_code]} not owned by user #{user.id}"
        return
      end

      # 統計情報と制限情報を更新
      # 基本URL情報（short_url、long_url、short_code）は変更しない
      updatable_attrs = {
        visit_count: short_url_attrs[:visit_count],
        meta: short_url_attrs[:meta],
        title: short_url_attrs[:title],
        valid_until: short_url_attrs[:valid_until],
        max_visits: short_url_attrs[:max_visits],
        tags: short_url_attrs[:tags]
      }

      short_url.assign_attributes(updatable_attrs)

      if short_url.changed?
        short_url.save!
        Rails.logger.info "Synced stats for short URL: #{short_url.short_code} for user #{user.id} (visits: #{short_url.visit_count})"
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
        valid_since: parse_date(data.dig("meta", "validSince")),
        valid_until: parse_date(data.dig("meta", "validUntil")),
        max_visits: data.dig("meta", "maxVisits"),
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
