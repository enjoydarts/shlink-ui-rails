module Shlink
  class ListShortUrlsService < BaseService
    def call(page: 1, items_per_page: nil, search_term: nil, tags: nil, order_by: nil, start_date: nil, end_date: nil)
      items_per_page ||= SystemSetting.get("performance.items_per_page", 20)
      params = build_params(page, items_per_page, search_term, tags, order_by, start_date, end_date)
      response = conn.get("/rest/v3/short-urls", params, api_headers)
      handle_response(response)
    end

    def call!(page: 1, items_per_page: nil, search_term: nil, tags: nil, order_by: nil, start_date: nil, end_date: nil)
      items_per_page ||= SystemSetting.get("performance.items_per_page", 20)
      call(page: page, items_per_page: items_per_page, search_term: search_term, tags: tags, order_by: order_by, start_date: start_date, end_date: end_date)
    rescue => e
      raise e
    end

    private

    def build_params(page, items_per_page, search_term, tags, order_by, start_date, end_date)
      params = {
        page: page,
        itemsPerPage: items_per_page
      }

      params[:searchTerm] = search_term if search_term.present?
      params[:tags] = tags if tags.present?
      params[:orderBy] = order_by if order_by.present?
      params[:startDate] = start_date.iso8601 if start_date.present?
      params[:endDate] = end_date.iso8601 if end_date.present?

      params
    end
  end
end
