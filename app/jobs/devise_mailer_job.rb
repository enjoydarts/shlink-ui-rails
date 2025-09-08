class DeviseMailerJob < ApplicationJob
  queue_as :mailers

  def perform(method_name, record, token = nil, opts = {})
    if token
      Devise::Mailer.public_send(method_name, record, token, opts).deliver_now
    else
      Devise::Mailer.public_send(method_name, record, opts).deliver_now
    end
  end
end
