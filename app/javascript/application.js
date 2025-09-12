// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "turnstile_manager"

// Force Turbo to be enabled
import { Turbo } from "@hotwired/turbo-rails"
Turbo.session.drive = true
