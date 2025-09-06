class MypageController < ApplicationController
  before_action :authenticate_user!

  def index
    @short_urls = current_user.recent_short_urls
    @total_urls = @short_urls.count
    @total_visits = @short_urls.sum(:visit_count)
    @active_urls = @short_urls.select(&:active?).count
  end
end
