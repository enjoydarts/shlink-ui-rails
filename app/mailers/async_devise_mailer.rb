class AsyncDeviseMailer < Devise::Mailer
  def confirmation_instructions(record, token, opts = {})
    DeviseMailerJob.perform_later(__method__, record, token, opts)
  end

  def reset_password_instructions(record, token, opts = {})
    DeviseMailerJob.perform_later(__method__, record, token, opts)
  end

  def unlock_instructions(record, token, opts = {})
    DeviseMailerJob.perform_later(__method__, record, token, opts)
  end

  def email_changed(record, opts = {})
    DeviseMailerJob.perform_later(__method__, record, nil, opts)
  end

  def password_change(record, opts = {})
    DeviseMailerJob.perform_later(__method__, record, nil, opts)
  end
end
