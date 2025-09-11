# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # Override create to add CAPTCHA verification
  def create
    # CAPTCHA検証を実行
    unless verify_captcha(params[:cf_turnstile_response])
      # パラメータが存在する場合のみリソースを作成
      if params[resource_name].present?
        self.resource = resource_class.new(sign_in_params)
      else
        self.resource = resource_class.new
      end
      render :new, status: :unprocessable_entity
      return
    end

    super
  end

  private

  # Deviseのsign_in_paramsをオーバーライド
  def sign_in_params
    return {} unless params[resource_name].present?
    
    params.require(resource_name).permit(:email, :password, :remember_me)
  end
end