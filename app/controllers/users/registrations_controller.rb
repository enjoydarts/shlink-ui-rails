class Users::RegistrationsController < Devise::RegistrationsController
  before_action :authenticate_user!
  before_action :configure_account_update_params, only: [:update]

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
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
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
end