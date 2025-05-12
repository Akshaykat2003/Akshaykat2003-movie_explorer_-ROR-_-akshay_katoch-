# spec/spec_helper.rb
ENV['RAILS_ENV'] ||= 'test'

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