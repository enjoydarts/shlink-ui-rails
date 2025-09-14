class Admin::AdminController < ApplicationController
  # Devise認証を必須とする
  before_action :authenticate_user!
  # 管理者権限チェック
  before_action :ensure_admin!

  # 管理者専用のレイアウト
  layout "admin"

  private

  # 管理者権限チェック
  def ensure_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "管理者権限が必要です。"
    end
  end
end
