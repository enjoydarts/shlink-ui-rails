# frozen_string_literal: true

class Users::TwoFactorAuthenticationController < ApplicationController
  before_action :authenticate_user_for_2fa!
  before_action :check_2fa_required, only: [:show, :verify]

  # 2FA認証画面表示
  def show
    # セッションから一時的なユーザー情報を取得
    @user = current_user_for_2fa
    redirect_to dashboard_path if @user.nil? || !@user.requires_two_factor?
  end

  # 2FAコード検証
  def verify
    @user = current_user_for_2fa
    
    unless @user&.requires_two_factor?
      redirect_to dashboard_path
      return
    end

    code = params[:totp_code]&.strip
    
    if code.blank?
      flash.now[:alert] = '認証コードを入力してください。'
      render :show, status: :unprocessable_entity
      return
    end

    if @user.verify_two_factor_code(code)
      # 2FA認証成功 - 正式にログイン
      complete_two_factor_authentication(@user)
      flash[:notice] = '2段階認証が完了しました。'
      redirect_to after_2fa_success_path
    else
      # 2FA認証失敗
      flash.now[:alert] = '認証コードが正しくありません。再度お試しください。'
      render :show, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "2FA verification error: #{e.message}"
    flash.now[:alert] = '認証処理でエラーが発生しました。再度お試しください。'
    render :show, status: :unprocessable_entity
  end

  private

  # 2FA用のユーザー認証チェック
  def authenticate_user_for_2fa!
    return if user_pending_2fa? || user_signed_in?
    
    redirect_to new_user_session_path, alert: 'ログインが必要です。'
  end

  # 2FA が必要かどうかをチェック
  def check_2fa_required
    user = current_user_for_2fa
    
    unless user&.requires_two_factor?
      if user_signed_in?
        redirect_to dashboard_path
      else
        redirect_to new_user_session_path, alert: 'ログインが必要です。'
      end
    end
  end

  # 2FA待ちのユーザーが存在するか
  def user_pending_2fa?
    session[:user_pending_2fa_id].present?
  end

  # 2FA待ち、または既にログイン済みのユーザーを取得
  def current_user_for_2fa
    if user_signed_in?
      current_user
    elsif session[:user_pending_2fa_id]
      User.find_by(id: session[:user_pending_2fa_id])
    end
  end

  # 2FA認証を完了させる
  def complete_two_factor_authentication(user)
    # セッションから一時的な情報をクリア
    session.delete(:user_pending_2fa_id)
    
    # 正式にログイン
    sign_in(user)
    
    # trackableがonの場合の記録更新
    user.update_tracked_fields(request) if user.respond_to?(:update_tracked_fields)
  end

  # 2FA成功後のリダイレクト先
  def after_2fa_success_path
    stored_location_for(:user) || dashboard_path
  end
end