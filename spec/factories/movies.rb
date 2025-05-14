# spec/factories/movies.rb
FactoryBot.define do
  factory :movie do
    title { Faker::Movie.title }
    genre { Faker::Book.genre }
    release_year { Faker::Number.between(from: 1900, to: 2025) }
    rating { Faker::Number.between(from: 1, to: 10).to_f }
    director { Faker::Name.name }
    duration { Faker::Number.between(from: 60, to: 180) }
    description { Faker::Lorem.paragraph }
    plan { 'basic' }
  end
end