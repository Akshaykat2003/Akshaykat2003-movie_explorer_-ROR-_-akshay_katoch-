# spec/models/movie_spec.rb
require 'rails_helper'

RSpec.describe Movie, type: :model do
  let(:movie) { create(:movie) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(movie).to be_persisted
    end

    it 'is not valid without a title' do
      movie.title = nil
      expect(movie).not_to be_valid
      expect(movie.errors[:title]).to include("can't be blank")
    end

    it 'is not valid without a genre' do
      movie.genre = nil
      expect(movie).not_to be_valid
      expect(movie.errors[:genre]).to include("can't be blank")
    end

    it 'is not valid without a release_year' do
      movie.release_year = nil
      expect(movie).not_to be_valid
      expect(movie.errors[:release_year]).to include("can't be blank")
    end

    it 'is not valid without a rating' do
      movie.rating = nil
      expect(movie).not_to be_valid
      expect(movie.errors[:rating]).to include("can't be blank")
    end

    it 'is not valid without a plan' do
      movie.plan = nil
      expect(movie).not_to be_valid
      expect(movie.errors[:plan]).to include("can't be blank")
    end
  end

  describe '.create_movie' do
    it 'creates a movie with valid params' do
      params = attributes_for(:movie)
      result = Movie.create_movie(params)
      expect(result[:success]).to be true
      expect(result[:movie]).to be_persisted
    end
  end

  describe '#update_movie' do
    it 'updates a movie with valid params' do
      params = { title: 'Updated Title' }
      result = movie.update_movie(params)
      expect(result[:success]).to be true
      expect(result[:movie].title).to eq('Updated Title')
    end
  end

  describe '#send_new_movie_notification' do
    it 'does not send a notification in test environment' do
      expect(movie.send_new_movie_notification).to be_nil
    end
  end
end