# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.unique.email }
    mobile_number { Faker::Number.number(digits: 10).to_s }
    role { 'user' }
    password { 'password123' }

    trait :supervisor do
      role { 'supervisor' }
    end

    trait :admin do
      role { 'admin' }
    end
  end

  # Define admin_user factory for ActiveAdmin
  factory :admin_user, class: 'AdminUser' do
    email { Faker::Internet.unique.email }
    password { 'password123' }
  end
end