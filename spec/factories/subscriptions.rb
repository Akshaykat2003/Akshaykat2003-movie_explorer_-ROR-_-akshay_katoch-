FactoryBot.define do
  factory :subscription do
    user
    plan { 'basic' }
    status { 'active' }
    session_id { nil }

    trait :gold do
      plan { 'gold' }
      status { 'pending' }
      session_id { "cs_test_#{SecureRandom.hex(8)}" }
    end

    trait :pending do
      status { 'pending' }
    end
  end
end