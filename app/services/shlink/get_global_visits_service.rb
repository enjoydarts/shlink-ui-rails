module Shlink
  class GetGlobalVisitsService < BaseService
    # 全体の訪問統計を取得
    def call(start_date: nil, end_date: nil, page: 1, items_per_page: 5000)
      params = build_params(start_date, end_date, page, items_per_page)
      response = conn.get("/rest/v3/visits", params, api_headers)
      handle_response(response)
    end

    def call!(start_date: nil, end_date: nil, page: 1, items_per_page: 5000)
      call(start_date: start_date, end_date: end_date, page: page, items_per_page: items_per_page)
    rescue => e
      raise e
    end

    private

    def build_params(start_date, end_date, page, items_per_page)
      params = {
        page: page,
        itemsPerPage: items_per_page
      }

      params[:startDate] = start_date.iso8601 if start_date.present?
      params[:endDate] = end_date.iso8601 if end_date.present?

      params
    end
  end
end
