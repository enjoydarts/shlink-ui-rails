class ApplicationController < ActionController::Base
  # Allow modern browsers with mobile support
  # Note: モバイルでの利用を考慮してバージョン制限を緩和
  allow_browser versions: Settings.browser_support.to_h

  protect_from_forgery with: :exception, prepend: true

  before_action :configure_permitted_parameters, if: :devise_controller?

  # Deviseの認証後リダイレクト先を設定
  def after_sign_in_path_for(resource)
    dashboard_path
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end
end
