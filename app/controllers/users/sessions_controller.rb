# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # Override create to add CAPTCHA verification
  def create
    # CAPTCHA検証を実行
    unless verify_captcha(params[:cf_turnstile_response])
      self.resource = resource_class.new(sign_in_params)
      respond_with resource, serialize_options(resource)
      return
    end

    super
  end

  private

  # Deviseのsign_in_paramsをオーバーライド
  def sign_in_params
    params.require(resource_name).permit(:email, :password, :remember_me)
  end
end