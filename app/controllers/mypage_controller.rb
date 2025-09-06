class MypageController < ApplicationController
  before_action :authenticate_user!

  def index
    @short_urls = current_user.recent_short_urls
    @total_urls = @short_urls.count
    @total_visits = @short_urls.sum(:visit_count)
    @active_urls = @short_urls.select(&:active?).count
  end

  def sync
    begin
      sync_service = Shlink::SyncShortUrlsService.new(current_user)
      synced_count = sync_service.call
      
      render json: {
        success: true,
        message: "#{synced_count}件の短縮URLを同期しました",
        synced_count: synced_count
      }
    rescue Shlink::Error => e
      Rails.logger.error "Sync failed for user #{current_user.id}: #{e.message}"
      render json: {
        success: false,
        message: "同期に失敗しました: #{e.message}"
      }, status: :bad_gateway
    rescue => e
      Rails.logger.error "Unexpected error during sync for user #{current_user.id}: #{e.message}"
      render json: {
        success: false,
        message: "予期しないエラーが発生しました"
      }, status: :internal_server_error
    end
  end
end
