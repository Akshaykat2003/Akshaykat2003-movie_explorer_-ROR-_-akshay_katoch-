# spec/models/wishlist_spec.rb
require 'rails_helper'

RSpec.describe Wishlist, type: :model do
  # Setup test data
  let(:user) { create(:user) }
  let(:movie) { create(:movie) }
  let(:another_movie) { create(:movie, title: 'Another Movie') }

  # Define wishlist factory inline to avoid modifying factories
  FactoryBot.define do
    factory :wishlist do
      user
      movie
    end
  end

  # Mock Cloudinary URLs to avoid real API calls
  before do
    allow_any_instance_of(Movie).to receive(:poster_url).and_return('http://example.com/poster.jpg')
    allow_any_instance_of(Movie).to receive(:banner_url).and_return('http://example.com/banner.jpg')
  end

  # Test associations manually
  describe 'associations' do
    it 'belongs to user' do
      wishlist = create(:wishlist, user: user, movie: movie)
      expect(wishlist.user).to eq(user)
      expect(Wishlist.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it 'belongs to movie' do
      wishlist = create(:wishlist, user: user, movie: movie)
      expect(wishlist.movie).to eq(movie)
      expect(Wishlist.reflect_on_association(:movie).macro).to eq(:belongs_to)
    end
  end

  # Test validations manually
  describe 'validations' do
    context 'when user has not wishlisted the movie' do
      it 'is valid' do
        wishlist = build(:wishlist, user: user, movie: movie)
        expect(wishlist).to be_valid
      end
    end

    context 'when user has already wishlisted the movie' do
      before { create(:wishlist, user: user, movie: movie) }

      it 'is not valid' do
        new_wishlist = build(:wishlist, user: user, movie: movie)
        expect(new_wishlist).not_to be_valid
        expect(new_wishlist.errors.full_messages).to include('User already wishlisted this movie')
      end
    end
  end

  # Test .add_to_wishlist
  describe '.add_to_wishlist' do
    context 'when movie does not exist' do
      it 'returns failure with error message' do
        result = Wishlist.add_to_wishlist(user, 999)
        expect(result).to eq(
          success: false,
          errors: ['Movie not found']
        )
      end
    end

    context 'when movie is not in wishlist' do
      it 'adds movie to wishlist and returns success' do
        result = Wishlist.add_to_wishlist(user, movie.id)
        expect(result).to eq(
          success: true,
          data: {
            message: 'Movie added to wishlist',
            movie_id: movie.id,
            is_wishlisted: true
          }
        )
        expect(user.wishlists.count).to eq(1)
        expect(user.wishlists.first.movie).to eq(movie)
      end
    end

    context 'when movie is already in wishlist' do
      before { create(:wishlist, user: user, movie: movie) }

      it 'removes movie from wishlist and returns success' do
        result = Wishlist.add_to_wishlist(user, movie.id)
        expect(result).to eq(
          success: true,
          data: {
            message: 'Movie removed from wishlist',
            movie_id: movie.id,
            is_wishlisted: false
          }
        )
        expect(user.wishlists.count).to eq(0)
      end
    end

    context 'when adding fails due to validation' do
      before do
        allow_any_instance_of(Wishlist).to receive(:save).and_return(false)
        allow_any_instance_of(Wishlist).to receive(:errors).and_return(
          double(full_messages: ['Validation error'])
        )
      end

      it 'returns failure with errors' do
        result = Wishlist.add_to_wishlist(user, movie.id)
        expect(result).to eq(
          success: false,
          errors: ['Validation error']
        )
      end
    end
  end

  # Test .remove_from_wishlist
  describe '.remove_from_wishlist' do
    context 'when movie is in wishlist' do
      before { create(:wishlist, user: user, movie: movie) }

      it 'removes movie from wishlist and returns success' do
        result = Wishlist.remove_from_wishlist(user, movie.id)
        expect(result).to eq(
          success: true,
          data: {
            message: 'Movie removed from wishlist',
            movie_id: movie.id,
            is_wishlisted: false
          }
        )
        expect(user.wishlists.count).to eq(0)
      end
    end

    context 'when movie is not in wishlist' do
      it 'returns failure with error message' do
        result = Wishlist.remove_from_wishlist(user, movie.id)
        expect(result).to eq(
          success: false,
          errors: ['Movie not in wishlist']
        )
      end
    end
  end

  # Test .clear_wishlist
  describe '.clear_wishlist' do
    context 'when user has wishlisted movies' do
      before do
        create(:wishlist, user: user, movie: movie)
        create(:wishlist, user: user, movie: another_movie)
      end

      it 'removes all movies from wishlist and returns success with count' do
        result = Wishlist.clear_wishlist(user)
        expect(result).to eq(
          success: true,
          data: {
            message: 'All wishlisted movies removed',
            count: 2
          }
        )
        expect(user.wishlists.count).to eq(0)
      end
    end

    context 'when wishlist is empty' do
      it 'returns success with count of 0' do
        result = Wishlist.clear_wishlist(user)
        expect(result).to eq(
          success: true,
          data: {
            message: 'All wishlisted movies removed',
            count: 0
          }
        )
      end
    end
  end

  # Test .wishlisted_movies
  describe '.wishlisted_movies' do
    context 'when wishlist is empty' do
      it 'returns success with empty array' do
        result = Wishlist.wishlisted_movies(user)
        expect(result).to eq(
          success: true,
          data: []
        )
      end
    end
  end
end