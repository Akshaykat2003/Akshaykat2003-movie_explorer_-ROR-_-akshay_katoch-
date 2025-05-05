
namespace :blacklist do
  desc "Clean up expired blacklisted tokens"
  task cleanup: :environment do
    count = BlacklistedToken.cleanup_expired
    puts "Deleted #{count} expired blacklisted tokens."
  end
end