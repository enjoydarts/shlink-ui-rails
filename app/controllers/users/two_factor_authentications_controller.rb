# frozen_string_literal: true

class Users::TwoFactorAuthenticationsController < ApplicationController
  before_action :authenticate_user_for_2fa!, only: [ :show, :verify ]
  before_action :check_2fa_required, only: [ :show, :verify ]
  before_action :authenticate_user!, only: [ :new, :create, :destroy, :backup_codes ]

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

    # WebAuthn認証を試行
    if params[:webauthn_credential].present?
      verify_webauthn_credential
      return
    end

    # TOTP/バックアップコード認証を試行
    verify_totp_or_backup_code
  rescue StandardError => e
    Rails.logger.error "2FA verification error: #{e.message}"
    flash.now[:alert] = "認証処理でエラーが発生しました。再度お試しください。"
    render :show, status: :unprocessable_entity
  end

  private

  # 2FA用のユーザー認証チェック
  def authenticate_user_for_2fa!
    # 2FA待ちのユーザーのみ許可（完全ログイン済みユーザーはダッシュボードへ）
    return if user_pending_2fa?

    if user_signed_in?
      redirect_to dashboard_path
    else
      redirect_to new_user_session_path, alert: "ログインが必要です。"
    end
  end

  # 2FA が必要かどうかをチェック
  def check_2fa_required
    user = current_user_for_2fa

    unless user&.requires_two_factor?
      if user_signed_in?
        redirect_to dashboard_path
      else
        redirect_to new_user_session_path, alert: "ログインが必要です。"
      end
    end
  end

  # 2FA待ちのユーザーが存在するか
  def user_pending_2fa?
    session[:user_pending_2fa_id].present?
  end

  # 2FA待ちのユーザーのみを取得
  def current_user_for_2fa
    if session[:user_pending_2fa_id]
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

  # WebAuthn認証を検証
  def verify_webauthn_credential
    challenge = session.delete(:webauthn_authentication_challenge)


    unless challenge
      flash.now[:alert] = "セッションが無効です。再度お試しください。"
      render :show, status: :unprocessable_entity
      return
    end

    credential_response = JSON.parse(params[:webauthn_credential])

    if WebauthnService.verify_authentication(@user, credential_response, challenge)
      # WebAuthn認証成功
      complete_two_factor_authentication(@user)
      flash[:notice] = "セキュリティキーによる認証が完了しました。"
      redirect_to after_2fa_success_path
    else
      # WebAuthn認証失敗
      flash.now[:alert] = "セキュリティキーでの認証に失敗しました。"
      render :show, status: :unprocessable_entity
    end
  rescue JSON::ParserError
    flash.now[:alert] = "無効なデータ形式です。"
    render :show, status: :unprocessable_entity
  end

  # TOTP/バックアップコード認証を検証
  def verify_totp_or_backup_code
    code = params[:totp_code]&.strip

    if code.blank?
      flash.now[:alert] = "認証コードを入力してください。"
      render :show, status: :unprocessable_entity
      return
    end

    if @user.verify_two_factor_code(code)
      # TOTP/バックアップコード認証成功
      complete_two_factor_authentication(@user)
      flash[:notice] = "2段階認証が完了しました。"
      redirect_to after_2fa_success_path
    else
      # TOTP/バックアップコード認証失敗
      flash.now[:alert] = "認証コードが正しくありません。再度お試しください。"
      render :show, status: :unprocessable_entity
    end
  end

  public

  # 2FA設定画面表示
  def new
    if current_user.skip_two_factor_for_oauth?
      redirect_to account_path, notice: "Google認証ユーザーは追加の二段階認証は不要です。"
      return
    end

    if current_user.totp_enabled?
      redirect_to account_path, notice: "認証アプリによる二段階認証は既に有効になっています。"
      return
    end

    @secret = current_user.two_factor_secret
    @qr_code = current_user.generate_two_factor_qr_code

    Rails.logger.debug "2FA Setup - Secret: #{@secret.present? ? 'Present' : 'Missing'}"
    Rails.logger.debug "2FA Setup - QR Code: #{@qr_code.present? ? 'Generated' : 'Failed'}"
  end

  # 2FA有効化
  def create
    if current_user.skip_two_factor_for_oauth?
      redirect_to account_path, alert: "Google認証ユーザーは追加の二段階認証は不要です。"
      return
    end

    code = params[:totp_code]&.strip

    if code.blank?
      flash.now[:alert] = "認証コードを入力してください。"
      redirect_to new_users_two_factor_authentications_path
      return
    end

    if current_user.enable_two_factor!(code)
      flash[:notice] = "二段階認証が有効になりました。バックアップコードを安全な場所に保管してください。"
      redirect_to account_path(anchor: "security")
    else
      flash.now[:alert] = "認証コードが正しくありません。再度お試しください。"
      redirect_to new_users_two_factor_authentications_path
    end
  end

  # 2FA無効化
  def destroy
    if current_user.skip_two_factor_for_oauth?
      redirect_to account_path, alert: "Google認証ユーザーは追加の二段階認証は不要です。"
      return
    end

    if current_user.disable_two_factor!
      flash[:notice] = "二段階認証を無効にしました。"
    else
      flash[:alert] = "二段階認証の無効化に失敗しました。"
    end

    redirect_to account_path(anchor: "security")
  end

  # バックアップコード再生成
  def backup_codes
    if current_user.skip_two_factor_for_oauth?
      redirect_to account_path, alert: "Google認証ユーザーは追加の二段階認証は不要です。"
      return
    end

    if current_user.totp_enabled?
      current_user.regenerate_two_factor_backup_codes!
      flash[:notice] = "新しいバックアップコードを生成しました。"
    else
      flash[:alert] = "認証アプリによる二段階認証が有効ではありません。"
    end

    respond_to do |format|
      format.html { redirect_to account_path(anchor: "security") }
      format.turbo_stream {
        redirect_to account_path(anchor: "security"), status: :see_other
      }
    end
  end
end
