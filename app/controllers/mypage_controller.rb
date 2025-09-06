class MypageController < ApplicationController
  before_action :authenticate_user!

  def index
    @search_query = params[:search]

    # 基本のクエリを構築
    base_scope = current_user.short_urls.recent

    # 検索機能
    if @search_query.present?
      @short_urls = base_scope.where(
        "title LIKE ? OR long_url LIKE ? OR short_code LIKE ? OR tags LIKE ?",
        "%#{@search_query}%", "%#{@search_query}%", "%#{@search_query}%", "%#{@search_query}%"
      ).page(params[:page])
    else
      @short_urls = base_scope.page(params[:page])
    end

    # 統計情報は全URLから計算
    all_urls = current_user.short_urls
    @total_urls = all_urls.count
    @total_visits = all_urls.sum(:visit_count)
    @active_urls = all_urls.select(&:active?).count
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

  def destroy
    short_code = params[:short_code]

    # セキュリティチェック: 現在のユーザーが所有するURLのみ削除可能
    short_url = current_user.short_urls.find_by(short_code: short_code)

    unless short_url
      render json: {
        success: false,
        message: "指定された短縮URLが見つかりません"
      }, status: :not_found
      return
    end

    begin
      # Shlink APIから削除
      delete_service = Shlink::DeleteShortUrlService.new(short_code)
      delete_service.call

      # ローカルDBからも削除
      short_url.destroy!

      Rails.logger.info "Successfully deleted short URL #{short_code} for user #{current_user.id}"

      render json: {
        success: true,
        message: "短縮URL「#{short_url.title.present? ? short_url.title : short_code}」を削除しました"
      }
    rescue Shlink::Error => e
      Rails.logger.error "Failed to delete short URL #{short_code} for user #{current_user.id}: #{e.message}"
      render json: {
        success: false,
        message: "削除に失敗しました: #{e.message}"
      }, status: :bad_gateway
    rescue => e
      Rails.logger.error "Unexpected error deleting short URL #{short_code} for user #{current_user.id}: #{e.message}"
      render json: {
        success: false,
        message: "予期しないエラーが発生しました"
      }, status: :internal_server_error
    end
  end
end
