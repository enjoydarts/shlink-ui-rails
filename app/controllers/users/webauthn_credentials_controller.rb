# frozen_string_literal: true

class Users::WebauthnCredentialsController < ApplicationController
  before_action :authenticate_user!, except: [:login_options, :authentication_options]
  before_action :set_user

  # 登録用オプションを返すAPI
  def registration_options
    options = WebauthnService.registration_options(@user)

    # セッションにチャレンジを保存
    session[:webauthn_registration_challenge] = options[:challenge]

    render json: options
  rescue StandardError => e
    Rails.logger.error "WebAuthn registration options error: #{e.message}"
    render json: { error: "セキュリティキーの登録準備に失敗しました" }, status: :unprocessable_entity
  end

  # 認証用オプションを返すAPI（2FA時）
  def authentication_options
    unless @user.webauthn_enabled?
      render json: { error: "セキュリティキーが登録されていません" }, status: :unprocessable_entity
      return
    end

    options = WebauthnService.authentication_options(@user)

    # セッションにチャレンジを保存
    session[:webauthn_authentication_challenge] = options[:challenge]

    render json: options
  rescue StandardError => e
    Rails.logger.error "WebAuthn authentication options error: #{e.message}"
    render json: { error: "セキュリティキーの認証準備に失敗しました" }, status: :unprocessable_entity
  end

  # ログイン時の認証用オプションを返すAPI
  def login_options
    email = params[:email]
    unless email.present?
      render json: { error: "メールアドレスが必要です" }, status: :bad_request
      return
    end

    user = User.find_by(email: email)
    unless user&.webauthn_enabled?
      render json: { error: "このユーザーはセキュリティキー認証が利用できません" }, status: :unprocessable_entity
      return
    end

    options = WebauthnService.authentication_options(user)

    # セッションにチャレンジとユーザーIDを保存
    session[:webauthn_login_challenge] = options[:challenge]
    session[:webauthn_login_user_id] = user.id

    render json: options
  rescue StandardError => e
    Rails.logger.error "WebAuthn login options error: #{e.message}"
    render json: { error: "セキュリティキーの認証準備に失敗しました" }, status: :unprocessable_entity
  end

  # セキュリティキーを登録
  def create
    challenge = session.delete(:webauthn_registration_challenge)

    unless challenge
      render json: { error: "セッションが無効です。再度お試しください" }, status: :unprocessable_entity
      return
    end

    credential_response = JSON.parse(params[:credential])
    nickname = params[:nickname].presence

    credential = WebauthnService.register_credential(@user, credential_response, challenge, nickname: nickname)

    render json: {
      success: true,
      message: "セキュリティキーを登録しました",
      credential: credential.display_info
    }
  rescue JSON::ParserError
    render json: { error: "無効なデータ形式です" }, status: :unprocessable_entity
  rescue StandardError => e
    Rails.logger.error "WebAuthn registration error: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # セキュリティキーの名前を変更
  def update
    credential = @user.webauthn_credentials.find(params[:id])
    
    if credential.update(nickname: params[:nickname])
      render json: {
        success: true,
        message: "セキュリティキーの名前を変更しました",
        credential: credential.display_info
      }
    else
      render json: {
        success: false,
        message: "名前の変更に失敗しました",
        errors: credential.errors.full_messages
      }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "セキュリティキーが見つかりません" }, status: :not_found
  rescue StandardError => e
    Rails.logger.error "WebAuthn update error: #{e.message}"
    render json: { error: "名前の変更に失敗しました" }, status: :unprocessable_entity
  end

  # セキュリティキーを削除
  def destroy
    if WebauthnService.remove_credential(@user, params[:id])
      respond_to do |format|
        format.html { redirect_to account_path, notice: "セキュリティキーを削除しました" }
        format.json { render json: { success: true, message: "セキュリティキーを削除しました" } }
      end
    else
      respond_to do |format|
        format.html { redirect_to account_path, alert: "セキュリティキーの削除に失敗しました" }
        format.json { render json: { success: false, message: "セキュリティキーの削除に失敗しました" }, status: :unprocessable_entity }
      end
    end
  rescue StandardError => e
    Rails.logger.error "WebAuthn removal error: #{e.message}"
    respond_to do |format|
      format.html { redirect_to account_path, alert: "セキュリティキーの削除に失敗しました" }
      format.json { render json: { success: false, message: "セキュリティキーの削除に失敗しました" }, status: :unprocessable_entity }
    end
  end

  private

  def set_user
    if action_name == 'login_options'
      # ログイン時は何もしない（メソッド内でユーザーを特定）
      return
    elsif action_name == 'authentication_options' && session[:user_pending_2fa_id]
      # 2FA認証中はセッションからユーザーを取得
      @user = User.find_by(id: session[:user_pending_2fa_id])
    else
      # 通常時はログイン済みユーザーを取得
      @user = current_user
    end
  end
end
