class PagesController < ApplicationController
  def home
    redirect_to dashboard_path if user_signed_in?
  end

  # RFC 2324 Easter Egg - I'm a teapot
  def teapot
    # Set custom headers for the teapot response
    response.headers["X-Teapot-Message"] = "I'm a teapot, not a coffee maker!"
    response.headers["X-RFC"] = "RFC 2324"
    response.headers["X-Easter-Egg"] = "true"

    # Log the teapot request for fun
    Rails.logger.info "🫖 Teapot request from #{request.remote_ip} - #{request.user_agent}"

    # Return the 418 status with our custom page
    render file: Rails.public_path.join("418.html"),
           status: 418,
           layout: false,
           content_type: "text/html"
  end
end
