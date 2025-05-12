# spec/rails_helper.rb
require 'spec_helper'

# Ensure Rails environment is only loaded via spec_helper.rb
unless defined?(Rails)
  raise "Rails environment must be loaded via spec_helper.rb"
end

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
end