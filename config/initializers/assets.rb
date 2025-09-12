# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets for Rails error pages and letter_opener
Rails.application.config.assets.precompile += %w[
  actioncable.js
  actioncable.esm.js
  application.js
  application.css
  tailwind.css
]
