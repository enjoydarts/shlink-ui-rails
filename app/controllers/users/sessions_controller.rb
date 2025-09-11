# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  before_action :disable_turbo_cache
  # Override create to add CAPTCHA verification and 2FA handling
  def create
    # CAPTCHA検証を実行
    unless verify_captcha
      # パラメータが存在する場合のみリソースを作成
      if params[resource_name].present?
        self.resource = resource_class.new(sign_in_params)
      else
        self.resource = resource_class.new
      end
      render :new, status: :unprocessable_entity
      return
    end

    # 通常のDevise認証を実行
    self.resource = warden.authenticate!(auth_options)

    if resource
      # 2FAが必要な場合は中間ステップへ
      if resource.requires_two_factor?
        handle_two_factor_required(resource)
      else
        # 2FAが不要な場合は通常ログイン完了
        complete_normal_login(resource)
      end
    else
      # 認証失敗
      respond_with_authentication_failure
    end
  end

  private

  # 2FA必要時の処理
  def handle_two_factor_required(user)
    # ユーザーIDをセッションに一時保存（まだ正式ログインはしない）
    session[:user_pending_2fa_id] = user.id

    # リダイレクト先を保存
    store_location_for(:user, after_sign_in_path_for(user))

    # 2FA画面にリダイレクト
    redirect_to users_two_factor_authentications_path
  end

  # 通常ログイン完了処理
  def complete_normal_login(user)
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, user)
    yield user if block_given?
    respond_with user, location: after_sign_in_path_for(user)
  end

  # 認証失敗時の処理
  def respond_with_authentication_failure
    flash.now[:alert] = "メールアドレスまたはパスワードが正しくありません。"
    self.resource = resource_class.new(sign_in_params)
    render :new, status: :unprocessable_entity
  end

  # Deviseのsign_in_paramsをオーバーライド
  def sign_in_params
    return {} unless params[resource_name].present?

    params.require(resource_name).permit(:email, :password, :remember_me)
  end

  # Turboキャッシュ無効化
  def disable_turbo_cache
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
  end
end
