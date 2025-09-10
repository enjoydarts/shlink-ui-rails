module Statistics
  class OverallController < ApplicationController
    before_action :authenticate_user!

    # 全体統計データをJSON形式で返却
    def index
      period = params[:period] || "30d"

      begin
        service = Statistics::OverallDataService.new(current_user)
        data = service.call(period)

        render json: {
          success: true,
          data: data,
          period: period,
          generated_at: Time.current.iso8601
        }
      rescue => e
        Rails.logger.error "統計データ生成エラー (user_id: #{current_user.id}): #{e.message}"

        render json: {
          success: false,
          error: "統計データの取得に失敗しました",
          message: e.message
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
  end
end
