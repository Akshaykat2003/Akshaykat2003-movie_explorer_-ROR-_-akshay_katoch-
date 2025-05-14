FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.unique.email }
    mobile_number { Faker::Number.number(digits: 10).to_s }
    role { 'user' }
    password { 'Password123' } # Ensure this matches the test

    trait :supervisor do
      role { 'supervisor' }
    end

    trait :admin do
      role { 'admin' }
    end
  end

  factory :admin_user, class: 'AdminUser' do
    email { Faker::Internet.unique.email }
    password { 'password123' }
  end
end