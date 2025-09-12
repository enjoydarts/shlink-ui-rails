class Admin::SessionsController < ApplicationController
  # 管理者ログインページのレイアウト
  layout "admin_auth"

  def new
    redirect_to admin_dashboard_path if user_signed_in? && current_user.admin?
  end

  def create
    user = User.find_by(email: params[:email])

    if user&.valid_password?(params[:password]) && user.admin?
      # 管理者ユーザーのログイン処理
      sign_in(user)
      redirect_to admin_dashboard_path, notice: "管理者としてログインしました。"
    else
      flash.now[:alert] = if user&.valid_password?(params[:password])
                           "管理者権限が必要です。"
      else
                           "メールアドレスまたはパスワードが正しくありません。"
      end
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    sign_out(current_user) if user_signed_in?
    redirect_to admin_login_path, notice: "ログアウトしました。"
  end

  private

  def session_params
    params.permit(:email, :password)
  end
end
