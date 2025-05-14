source "https://rubygems.org"

ruby "3.1.4"

# Core Rails
gem "rails", "~> 7.1.5", ">= 7.1.5.1"
gem "pg", "~> 1.1" # PostgreSQL database
gem "puma", ">= 5.0" # Web server
gem "jbuilder" # JSON API responses
gem "bootsnap", require: false # Speeds up boot time

# Environment Variables
gem "dotenv-rails", groups: [:development, :test] # Load .env variables

# Authentication
gem "bcrypt", "~> 3.1.7" # Password hashing
gem "jwt" # JWT-based authentication

# Admin Panel
gem "activeadmin" # Admin interface
gem 'chartkick'
gem 'groupdate'

gem 'devise'

gem "sassc-rails" # Required for ActiveAdmin styling

gem 'sprockets-rails'


# CORS for API
gem "rack-cors" # Enable CORS for frontend API calls

# Windows timezone fix
gem "tzinfo-data", platforms: %i[windows jruby]

# Development and Test
group :development, :test do
  gem "debug", platforms: %i[mri windows] # Debugging
  gem "factory_bot_rails" # Test data generation
end

group :development do
  gem "web-console" 
  gem "error_highlight", ">= 0.4.0", platforms: [:ruby] 
end

group :test do
  gem 'webmock' 
  gem 'database_cleaner-active_record' 
end

group :test do
  gem 'simplecov', require: false
  gem 'simplecov-lcov', require: false
end

gem "rswag"
gem 'faker'
gem "rspec-rails"
gem 'rswag-api'
gem 'rswag-ui'
gem 'rswag-specs'

gem 'activestorage', '~> 7.1.5'
gem 'cloudinary', '~> 1.16'

gem "kaminari" # Pagination
gem 'httparty'
gem 'googleauth'
gem 'stripe'


