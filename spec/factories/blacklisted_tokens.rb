FactoryBot.define do
  factory :blacklisted_token do
    token { "MyString" }
    expires_at { "2025-05-05 10:51:03" }
  end
end
