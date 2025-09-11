class Users::RegistrationsController < Devise::RegistrationsController
  before_action :authenticate_user!
  before_action :configure_account_update_params, only: [ :update ]
  before_action :configure_account_delete_params, only: [ :destroy ]

  # Override create to add CAPTCHA verification
  def create
    # CAPTCHA検証を実行
    unless verify_captcha(params[:cf_turnstile_response])
      self.resource = resource_class.new(sign_up_params)
      resource.validate # バリデーションエラーを表示するため
      respond_with resource
      return
    end

    super
  end

  # Override destroy to handle OAuth users
  def destroy
    # Check confirmation based on user type
    if resource.from_omniauth?
      # OAuth users need to type "削除" to confirm
      unless params[:user][:delete_confirmation] == "削除"
        redirect_to account_path, alert: t("accounts.messages.delete_confirmation_failed")
        return
      end
    else
      # Regular users need current password
      unless resource.valid_password?(params[:user][:current_password])
        redirect_to account_path, alert: t("accounts.messages.current_password_invalid")
        return
      end
    end

    # Proceed with deletion
    resource.destroy
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
    set_flash_message! :notice, :destroyed
    yield resource if block_given?
    respond_with_navigational(resource) { redirect_to after_sign_out_path_for(resource_name) }
  end

  # Override update to provide better user experience
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    resource_updated = update_resource(resource, account_update_params)
    yield resource if block_given?

    if resource_updated
      set_flash_message_for_update(resource, prev_unconfirmed_email)
      bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?

      respond_with resource, location: after_update_path_for(resource)
    else
      clean_up_passwords resource
      set_minimum_password_length
      redirect_to account_path, alert: format_error_messages(resource.errors)
    end
  end

  protected

  # Redirect to account settings page after update
  def after_update_path_for(resource)
    account_path
  end

  # Configure permitted parameters for account update
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  # Configure permitted parameters for account deletion
  def configure_account_delete_params
    params.require(:user).permit(:current_password, :delete_confirmation)
  end

  private

  def set_flash_message_for_update(resource, prev_unconfirmed_email)
    return unless is_flashing_format?

    flash_key = if update_needs_confirmation?(resource, prev_unconfirmed_email)
                  :update_needs_confirmation
    elsif sign_in_after_change_password?
                  :updated
    else
                  :updated_but_not_signed_in
    end

    case flash_key
    when :update_needs_confirmation
      flash[:notice] = "アカウント情報を更新しました。新しいメールアドレスを確認するため、確認メールをお送りしました。"
    when :updated
      flash[:notice] = "アカウント情報を正常に更新しました。"
    when :updated_but_not_signed_in
      flash[:notice] = "アカウント情報を更新しました。パスワードが変更されたため、再度ログインしてください。"
    end
  end

  def format_error_messages(errors)
    messages = []
    errors.each do |error|
      case error.attribute
      when :email
        messages << "メールアドレス: #{error.message}"
      when :password
        messages << "パスワード: #{error.message}"
      when :password_confirmation
        messages << "パスワード確認: #{error.message}"
      when :current_password
        messages << "現在のパスワード: #{error.message}"
      when :name
        messages << "名前: #{error.message}"
      else
        messages << error.full_message
      end
    end
    messages.join(", ")
  end

  def update_needs_confirmation?(resource, previous_unconfirmed_email)
    resource.respond_to?(:pending_reconfirmation?) &&
      resource.pending_reconfirmation? &&
      previous_unconfirmed_email != resource.unconfirmed_email
  end

  # Override update_resource to handle OAuth users
  def update_resource(resource, params)
    # For OAuth users, we don't require current password for profile/email updates
    if resource.from_omniauth?
      # Prevent email changes for OAuth users
      if params[:email].present? && params[:email] != resource.email
        resource.errors.add(:email, "Google認証ユーザーはメールアドレスを変更できません")
        return false
      end

      # If updating password and user doesn't have one yet, skip current password validation
      if params[:password].present? && !resource.has_password?
        resource.update(params.except(:current_password, :email))
      elsif params[:password].blank?
        # Profile update without password change (exclude email for OAuth users)
        resource.update_without_password(params.except(:current_password, :email))
      else
        # Password update for OAuth user who already has a password
        resource.update_with_password(params.except(:email))
      end
    else
      # Regular users need current password for all updates
      if params[:password].present?
        resource.update_with_password(params)
      else
        resource.update_without_password(params.except(:current_password))
      end
    end
  end
end
