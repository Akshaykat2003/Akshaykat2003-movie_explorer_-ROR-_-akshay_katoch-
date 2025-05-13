require 'spec_helper'

# Load Rails environment
require_relative '../config/environment'

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'
require 'factory_bot_rails'
require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)

# Checks for pending migrations and applies them before tests are run.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Fixture paths for ActiveRecord
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods

  # Use transactional fixtures for database cleanup
  config.use_transactional_fixtures = true

  # Infer spec type from file location (e.g., type: :request for requests)
  config.infer_spec_type_from_file_location!

  # Filter Rails gems from backtraces for cleaner error messages
  config.filter_rails_from_backtrace!

  # Optional: Add global setup
  config.before(:suite) do
    # Ensure the database is clean before the suite runs
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end
end