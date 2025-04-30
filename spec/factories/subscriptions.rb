FactoryBot.define do
  factory :subscription do
    user { nil }
    plan { 1 }
    status { "MyString" }
    payment_id { "MyString" }
  end
end
