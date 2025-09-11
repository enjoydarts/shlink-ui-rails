# frozen_string_literal: true

class Users::WebauthnCredentialsController < ApplicationController
  before_action :authenticate_user!
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

  # 認証用オプションを返すAPI
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

  # セキュリティキーを削除
  def destroy
    if WebauthnService.remove_credential(@user, params[:id])
      redirect_to account_path, notice: "セキュリティキーを削除しました"
    else
      redirect_to account_path, alert: "セキュリティキーの削除に失敗しました"
    end
  rescue StandardError => e
    Rails.logger.error "WebAuthn removal error: #{e.message}"
    redirect_to account_path, alert: "セキュリティキーの削除に失敗しました"
  end

  private

  def set_user
    @user = current_user
  end
end
