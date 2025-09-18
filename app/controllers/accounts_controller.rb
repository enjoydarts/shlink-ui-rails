class AccountsController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(user_params)
      respond_to do |format|
        format.html do
          flash[:notice] = "設定が更新されました。"
          redirect_to account_path
        end
        format.json do
          render json: {
            success: true,
            message: "設定が更新されました。",
            theme: @user.theme_preference
          }
        end
      end
    else
      respond_to do |format|
        format.html do
          flash.now[:alert] = "設定の更新に失敗しました。"
          render :show
        end
        format.json do
          render json: {
            success: false,
            message: "設定の更新に失敗しました。",
            errors: @user.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :theme_preference)
  end

  def resource_name
    :user
  end

  def resource
    @user ||= current_user
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  helper_method :resource_name, :resource, :devise_mapping
end
