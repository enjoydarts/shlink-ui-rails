source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2", ">= 8.0.2.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use mysql as the database for Active Record
gem "mysql2", "~> 0.5"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

gem "faraday"
gem "faraday_middleware"

# Authentication and authorization
gem "devise"
gem "omniauth"
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection"

# DB schema management
gem "ridgepole"

# Configuration management
gem "config"

# Pagination
gem "kaminari"

# MailerSend API for email delivery (production)
gem "mailersend-ruby"

# Two-Factor Authentication
gem "rotp"        # TOTP generation and verification
gem "rqrcode"     # QR code generation
gem "webauthn", "~> 3.4.1"    # FIDO2/WebAuthn for physical security keys

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mingw mswin x64_mingw ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # N+1 query detection [https://github.com/flyerhzm/bullet]
  gem "bullet"

  gem "dotenv-rails"

  # RSpec for testing
  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails", "~> 6.5"
  gem "faker", "~> 3.2"
  gem "rails-controller-testing", "~> 1.0"
end

group :test do
  # Test helpers
  gem "webmock", "~> 3.20"
  gem "vcr", "~> 6.2"
  gem "shoulda-matchers", "~> 6.0"
  gem "capybara", "~> 3.40"
  gem "selenium-webdriver", "~> 4.26"

  # CI/CD レポート用
  gem "rspec_junit_formatter", "~> 0.6"
  gem "simplecov", "~> 0.22", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Email testing in development
  gem "letter_opener_web"
end

gem "importmap-rails", "~> 2.2"

gem "turbo-rails", "~> 2.0"

gem "stimulus-rails", "~> 1.3"

gem "tailwindcss-rails", "~> 4.3"
gem "tailwindcss-ruby", "~> 4.1"
