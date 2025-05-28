ENV['RAILS_ENV'] ||= 'test'

# Ensure this is at the very top of the file
require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'      # Ignore the spec directory
  add_filter '/config/'    # Ignore the config directory
  add_filter '/vendor/'
  add_filter '/app/admin/' 
  add_filter  'app/services/'
  add_filter '/app/helpers/'   # Ignore vendor directory (e.g., bundled gems)
  add_filter '/app/controllers/api/v1/wishlists_controller.rb' # Ignore specific API controller

  # Optional: Group your files for better reporting
  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'


end

# Guard to prevent multiple loads of the Rails environment
unless defined?(RailsEnvLoaded)
  RailsEnvLoaded = true
  require_relative '../config/environment'

  # Prevent database truncation if the environment is production
  abort("The Rails environment is running in production mode!") if Rails.env.production?
end

# Basic RSpec configuration
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end