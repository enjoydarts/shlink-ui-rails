class AccountsController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
  end

  private

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