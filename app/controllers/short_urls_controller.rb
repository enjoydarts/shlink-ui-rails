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
      result = Shlink::Client.new.create_short_url(@shorten.long_url, @shorten.slug)
      Rails.logger.info "Shlink API result: #{result.inspect}"
      @result = { short_url: result["shortUrl"] }
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

  private

  def shorten_params
    params.require(:shorten_form).permit(:long_url, :slug)
  end
end
