module Statistics
  class IndividualController < ApplicationController
    before_action :authenticate_user!

    # 個別URL統計データをJSON形式で返却
    def show
      short_code = params[:short_code]
      period = validate_period(params[:period] || "30d")

      return render_not_found unless short_code.present?

      begin
        # ユーザーがこのshort_codeを所有しているかチェック
        unless current_user.short_urls.exists?(short_code: short_code)
          return render json: {
            success: false,
            error: "指定されたURLが見つかりません",
            message: "このURLは存在しないか、アクセス権限がありません"
          }, status: :not_found
        end

        service = Statistics::IndividualUrlDataService.new(current_user, short_code)
        data = service.call(period)

        render json: {
          success: true,
          data: data,
          period: period,
          short_code: short_code,
          generated_at: Time.current.iso8601
        }
      rescue Shlink::Error => e
        Rails.logger.error "Shlink API エラー (user_id: #{current_user.id}, short_code: #{short_code}): #{e.message}"

        render json: {
          success: false,
          error: "統計データが取得できませんでした",
          message: "このURLの訪問データが見つかりません"
        }, status: :unprocessable_entity
      rescue => e
        Rails.logger.error "個別URL統計データ生成エラー (user_id: #{current_user.id}, short_code: #{short_code}): #{e.message}"

        render json: {
          success: false,
          error: "個別URL統計データの取得に失敗しました",
          message: e.message
        }, status: :internal_server_error
      end
    end

    # ユーザーのURL一覧を返却（URL選択UI用）
    def url_list
      begin
        urls = current_user.short_urls
          .select(:id, :short_code, :short_url, :long_url, :title, :date_created, :visit_count)
          .order(date_created: :desc)
          .limit(100)

        formatted_urls = urls.map do |url|
          {
            short_code: url.short_code,
            short_url: url.short_url,
            title: url.title.present? ? url.title : url.long_url.truncate(50),
            long_url: url.long_url,
            visit_count: url.visit_count || 0,
            date_created: url.date_created.strftime("%Y/%m/%d")
          }
        end

        render json: {
          success: true,
          urls: formatted_urls
        }
      rescue => e
        Rails.logger.error "URL一覧取得エラー (user_id: #{current_user.id}): #{e.message}"

        render json: {
          success: false,
          error: "URL一覧の取得に失敗しました"
        }, status: :internal_server_error
      end
    end

    private

    # 許可されたパラメータのバリデーション
    def validate_period(period)
      allowed_periods = %w[7d 30d 90d 365d]
      return "30d" unless allowed_periods.include?(period)

      period
    end

    def render_not_found
      render json: {
        success: false,
        error: "指定されたURLが見つかりません"
      }, status: :not_found
    end
  end
end
