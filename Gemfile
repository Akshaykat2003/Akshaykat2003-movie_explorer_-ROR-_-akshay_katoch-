source "https://rubygems.org"

ruby "3.1.4"

# Core Rails
gem "rails", "~> 7.1.5", ">= 7.1.5.1"
gem "sprockets-rails"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"

# Environment Variables
gem "dotenv-rails"

# JWT-based Authentication
gem "bcrypt", "~> 3.1.7"
gem "jwt"

# Admin Panel
gem "activeadmin"
gem "devise"

# File Uploads (ActiveStorage)
gem "image_processing", "~> 1.2"

# Swagger/OpenAPI for API Docs
gem "rswag"

# Windows zone fix
gem "tzinfo-data", platforms: %i[windows jruby]

# Bootsnap for speed
gem "bootsnap", require: false

group :development, :test do
  # Debugging tools
  gem "debug", platforms: %i[mri windows]

  # Testing framework
  gem "rspec-rails"
  gem "factory_bot_rails"
end

group :development do
  gem "web-console"
  gem "error_highlight", ">= 0.4.0", platforms: [:ruby]
end
