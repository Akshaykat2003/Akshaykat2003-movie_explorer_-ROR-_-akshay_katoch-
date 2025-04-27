FactoryBot.define do
  factory :movie do
    title { "MyString" }
    genre { "MyString" }
    release_year { 1 }
    rating { 1.5 }
    director { "MyString" }
    duration { 1 }
    description { "MyText" }
    plan { 1 }
  end
end
