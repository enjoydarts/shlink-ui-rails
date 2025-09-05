class ShortUrlsController < ApplicationController
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
      Rails.logger.info "Calling Shlink API with URL: #{@shorten.long_url}, slug: #{@shorten.slug}"
      result = Shlink::CreateShortUrlService.new.call(
        long_url: @shorten.long_url,
        slug: @shorten.slug
      )
      Rails.logger.info "Shlink API result: #{result.inspect}"
      
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
    @error = e.message
    respond_to do |f|
      f.turbo_stream
      f.html { render :new, status: :bad_gateway }
    end
  end

  def qr_code
    short_code = params[:short_code]
    size = params[:size]&.to_i || 300
    format = params[:format] || 'png'
    
    qr_data = Shlink::GetQrCodeService.new.call(
      short_code: short_code,
      size: size,
      format: format
    )
    
    send_data qr_data[:data], 
      type: qr_data[:content_type],
      disposition: 'inline',
      filename: "qr-#{short_code}.#{format}"
      
  rescue Shlink::Error => e
    render json: { error: e.message }, status: :bad_gateway
  end

  private

  def shorten_params
    params.require(:shorten_form).permit(:long_url, :slug, :include_qr_code)
  end
end
