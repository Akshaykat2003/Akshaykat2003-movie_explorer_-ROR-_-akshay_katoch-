# spec/models/movie_spec.rb
require 'rails_helper'

RSpec.describe Movie, type: :model do
  before do
    # Use valid plan values: 'basic', 'gold', 'platinum'
    @movie1 = Movie.create(title: 'Inception', genre: 'Sci-Fi', release_year: 2010, rating: 9.5, plan: 'basic')
    @movie2 = Movie.create(title: 'Interstellar', genre: 'Sci-Fi', release_year: 2014, rating: 9.0, plan: 'gold')
    @movie3 = Movie.create(title: 'The Dark Knight', genre: 'Action', release_year: 2008, rating: 9.0, plan: 'platinum')
  end

  it 'searches for movies by title' do
    result = Movie.search_and_filter({ search: 'Inception', genre: nil })
    expect(result).to include(@movie1)
    expect(result).to_not include(@movie2)
  end

  it 'filters movies by genre' do
    result = Movie.search_and_filter({ search: nil, genre: 'Sci-Fi' })
    expect(result).to include(@movie1)
    expect(result).to include(@movie2)
    expect(result).to_not include(@movie3)
  end

  it 'searches by title and filters by genre' do
    result = Movie.search_and_filter({ search: 'Inter', genre: 'Sci-Fi' })
    expect(result).to include(@movie2)
    expect(result).to_not include(@movie1)
  end

  it 'returns an empty array when no match is found' do
    result = Movie.search_and_filter({ search: 'Nonexistent', genre: 'Action' })
    expect(result).to be_empty
  end
end
