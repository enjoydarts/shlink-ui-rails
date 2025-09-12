# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Manually pin controllers
pin "controllers/clipboard_controller", to: "controllers/clipboard_controller.js"
pin "controllers/submitter_controller", to: "controllers/submitter_controller.js"

# Turnstile manager
pin "turnstile_manager", to: "turnstile_manager.js"
