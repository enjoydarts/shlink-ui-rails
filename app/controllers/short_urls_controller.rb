class ShortUrlsController < ApplicationController
  before_action :authenticate_user!
  def new
    @shorten = ShortenForm.new
    @result  = nil
  end

  def test
    # テスト用アクション
  end

  def create
    @shorten = ShortenForm.new(shorten_params)
    Rails.logger.info "Form valid: #{@shorten.valid?}"
    Rails.logger.info "Form errors: #{@shorten.errors.full_messages}"

    if @shorten.valid?
      Rails.logger.info "Calling Shlink API with URL: #{@shorten.long_url}, slug: #{@shorten.slug}, valid_until: #{@shorten.valid_until}, max_visits: #{@shorten.max_visits}, tags: #{@shorten.tags_array}"
      result = Shlink::CreateShortUrlService.new.call(
        long_url: @shorten.long_url,
        slug: @shorten.slug,
        valid_until: @shorten.valid_until,
        max_visits: @shorten.max_visits,
        tags: @shorten.tags_array
      )
      Rails.logger.info "Shlink API result: #{result.inspect}"

      # Save the short URL to the database with user association
      save_short_url_to_database(result)

      @result = { short_url: result["shortUrl"] }

      # QRコードが要求された場合は取得
      if @shorten.include_qr_code
        short_code = result["shortCode"]
        @result[:qr_code_url] = qr_code_path(short_code: short_code)
      end

      Rails.logger.info "Setting @result: #{@result.inspect}"
      respond_to do |f|
        f.turbo_stream
        f.html { redirect_to root_path, notice: "短縮しました" }
      end
    else
      respond_to do |f|
        f.turbo_stream
        f.html { render :new, status: :unprocessable_entity }
      end
    end
  rescue Shlink::Error => e
    Rails.logger.error "Shlink error: #{e.message}"
    flash.now[:alert] = e.message
    respond_to do |f|
      f.turbo_stream
      f.html { render :new, status: :bad_gateway }
    end
  end

  def edit
    short_code = params[:short_code]
    @short_url = current_user.short_urls.active.find_by(short_code: short_code)

    unless @short_url
      respond_to do |format|
        format.turbo_stream { head :not_found }
        format.html { redirect_to mypage_path, alert: "指定された短縮URLが見つかりません" }
        format.json {
          render json: {
            success: false,
            message: "指定された短縮URLが見つかりません"
          }, status: :not_found
        }
      end
      return
    end

    @edit_form = EditShortUrlForm.from_short_url(@short_url)

    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def update
    short_code = params[:short_code]
    @short_url = current_user.short_urls.active.find_by(short_code: short_code)

    unless @short_url
      respond_to do |format|
        format.turbo_stream { head :not_found }
        format.html { redirect_to mypage_path, alert: "指定された短縮URLが見つかりません" }
        format.json {
          render json: {
            success: false,
            message: "指定された短縮URLが見つかりません"
          }, status: :not_found
        }
      end
      return
    end

    @edit_form = EditShortUrlForm.new(edit_short_url_params.merge(short_code: short_code))

    if @edit_form.valid?
      begin
        # Shlink APIで更新
        result = Shlink::UpdateShortUrlService.new.call(
          short_code: short_code,
          **@edit_form.update_params
        )

        # ローカルDBも更新
        local_update_success = update_local_short_url(result)
        if local_update_success
          Rails.logger.info "Successfully updated local database for #{short_code}"
        else
          Rails.logger.error "Failed to update local database for #{short_code}, but Shlink update was successful"
          # ローカルDBの更新に失敗してもShlinkの更新は成功しているため、ユーザーには成功を通知
          # ただし、同期が必要であることを伝える
        end


        respond_to do |format|
          format.turbo_stream { render :update_success }
          format.json {
            render json: {
              success: true,
              message: "短縮URLを更新しました"
            }
          }
        end
      rescue Shlink::Error => e
        Rails.logger.error "Shlink update error: #{e.message}"
        respond_to do |format|
          format.turbo_stream { render :update_error }
          format.json {
            render json: {
              success: false,
              message: "更新に失敗しました: #{e.message}"
            }, status: :bad_gateway
          }
        end
      end
    else
      respond_to do |format|
        format.turbo_stream { render :edit }
        format.json {
          render json: {
            success: false,
            message: "入力内容に問題があります",
            errors: @edit_form.errors.full_messages
          }, status: :unprocessable_content
        }
      end
    end
  end

  def qr_code
    short_code = params[:short_code]
    size = params[:size]&.to_i || 300
    format = params[:format] || "png"

    qr_data = Shlink::GetQrCodeService.new.call(
      short_code: short_code,
      size: size,
      format: format
    )

    send_data qr_data[:data],
      type: qr_data[:content_type],
      disposition: "inline",
      filename: "qr-#{short_code}.#{format}"

  rescue Shlink::Error => e
    render json: { error: e.message }, status: :bad_gateway
  end

  private

  def shorten_params
    params.require(:shorten_form).permit(:long_url, :slug, :include_qr_code, :valid_until, :max_visits, :tags)
  end

  def edit_short_url_params
    params.require(:edit_short_url_form).permit(:title, :long_url, :valid_until, :max_visits, :tags, :custom_slug)
  end

  def save_short_url_to_database(shlink_result)
    short_url_data = {
      short_code: shlink_result["shortCode"],
      short_url: shlink_result["shortUrl"],
      long_url: shlink_result["longUrl"],
      domain: shlink_result["domain"],
      title: shlink_result["title"],
      tags: shlink_result["tags"]&.to_json,
      meta: shlink_result["meta"]&.to_json,
      visit_count: 0,
      valid_since: parse_date(shlink_result["validSince"]),
      valid_until: parse_date(shlink_result["validUntil"]),
      max_visits: shlink_result["maxVisits"],
      crawlable: shlink_result["crawlable"] != false,
      forward_query: shlink_result["forwardQuery"] != false,
      date_created: parse_date(shlink_result["dateCreated"]) || Time.current,
      user: current_user
    }

    short_url = current_user.short_urls.find_or_initialize_by(short_code: short_url_data[:short_code])
    short_url.assign_attributes(short_url_data.except(:user))
    short_url.save!

    Rails.logger.info "Saved short URL to database: #{short_url.short_code}"
  rescue => e
    Rails.logger.error "Failed to save short URL to database: #{e.message}"
    # Don't fail the request if database save fails
  end

  def parse_date(date_string)
    return nil if date_string.blank?

    Time.zone.parse(date_string)
  rescue => e
    Rails.logger.warn "Failed to parse date: #{date_string} - #{e.message}"
    nil
  end

  def update_local_short_url(shlink_result)
    meta = shlink_result["meta"] || {}
    short_url_data = {
      title: shlink_result["title"],
      long_url: shlink_result["longUrl"],
      tags: shlink_result["tags"]&.to_json,
      meta: shlink_result["meta"]&.to_json,
      valid_since: parse_date(meta["validSince"]),
      valid_until: parse_date(meta["validUntil"]),
      max_visits: meta["maxVisits"],
      crawlable: shlink_result["crawlable"] != false,
      forward_query: shlink_result["forwardQuery"] != false
    }

    @short_url.assign_attributes(short_url_data)
    @short_url.save!
    @short_url.reload  # 最新データでリロード

    Rails.logger.info "Updated short URL in database: #{@short_url.short_code} - title: #{@short_url.title}"
    true
  rescue => e
    Rails.logger.error "Failed to update short URL in database: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"
    Rails.logger.error "Shlink result that failed to save: #{shlink_result.inspect}"

    # エラーを再発生させず、falseを返して失敗を示す
    false
  end
end
