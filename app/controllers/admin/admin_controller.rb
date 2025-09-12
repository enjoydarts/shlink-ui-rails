class Admin::AdminController < ApplicationController
  # 管理者認証を必須とする
  before_action :authenticate_admin!

  # 管理者専用のレイアウト
  layout "admin"

  private

  # 管理者認証チェック
  def authenticate_admin!
    redirect_to admin_login_path unless user_signed_in? && current_user.admin?
  end

  # 管理者ダッシュボードへリダイレクト（ログイン後のデフォルト）
  def after_sign_in_path_for(resource)
    if resource.admin?
      admin_dashboard_path
    else
      super
    end
  end

  # 管理者権限チェック（ヘルパーメソッド）
  def ensure_admin!
    redirect_to root_path, alert: "管理者権限が必要です。" unless current_user&.admin?
  end
end
