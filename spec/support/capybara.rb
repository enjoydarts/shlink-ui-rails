# Capybara configuration for system tests
require 'capybara/rails'
require 'capybara/rspec'

# Configure Capybara settings
Capybara.default_max_wait_time = 5
Capybara.server_host = 'localhost'
Capybara.server_port = 3001

# Use rack_test driver for non-JS tests (faster in Docker)
Capybara.default_driver = :rack_test

RSpec.configure do |config|
  # Include Capybara DSL in system tests
  config.include Capybara::DSL, type: :system

  # Use rack_test for non-JS tests, rack_test for JS tests too in Docker
  config.before(:each, type: :system) do |example|
    if example.metadata[:js]
      # For JS tests, use rack_test with simple assertions
      driven_by :rack_test
    else
      driven_by :rack_test
    end
  end
end
