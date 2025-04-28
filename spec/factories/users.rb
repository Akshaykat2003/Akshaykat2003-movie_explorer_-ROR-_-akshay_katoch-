FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    email { Faker::Internet.unique.email }
    password { 'password123' }
    mobile_number { Faker::Number.number(digits: 10).to_s }  
    role { 'user' }

    trait :admin do
      role { 'admin' }
    end
   
    trait :admin do
      role { 'supervisor' }
    end
  end
end