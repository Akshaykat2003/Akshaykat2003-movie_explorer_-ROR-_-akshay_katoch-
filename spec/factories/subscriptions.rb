FactoryBot.define do
  factory :subscription do
    user
    plan { 'basic' }
    status { 'active' }
    session_id { nil }
    session_expires_at { nil }
    expiry_date { nil }

    trait :gold do
      plan { 'gold' }
      status { 'pending' }
      session_id { "cs_test_#{SecureRandom.hex(8)}" }
      session_expires_at { 1.hour.from_now }
      expiry_date { 1.month.from_now }
    end

    trait :pending do
      status { 'pending' }
      session_id { "cs_test_#{SecureRandom.hex(8)}" }
      session_expires_at { 1.hour.from_now }
      expiry_date { 1.month.from_now }
    end
  end
end