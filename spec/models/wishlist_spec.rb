
require 'rails_helper'

RSpec.describe Wishlist, type: :model do
  let(:user) { create(:user) }
  let(:movie) { create(:movie) }
  let(:another_movie) { create(:movie) }

  describe 'associations' do
    it 'belongs to user' do
      wishlist = create(:wishlist, user: user, movie: movie)
      expect(wishlist.user).to eq(user)
    end

    it 'belongs to movie' do
      wishlist = create(:wishlist, user: user, movie: movie)
      expect(wishlist.movie).to eq(movie)
    end
  end

  describe 'validations' do
    context 'when user has not wishlisted the movie' do
      it 'is valid' do
        wishlist = build(:wishlist, user: user, movie: movie)
        expect(wishlist).to be_valid
      end
    end

    context 'when user has already wishlisted the movie' do
      before { create(:wishlist, user: user, movie: movie) }

      it 'is not in valid wishlist' do
        wishlist = build(:wishlist, user: user, movie: movie)
        expect(wishlist).not_to be_valid
        expect(wishlist.errors[:user_id]).to include("already wishlisted this movie")
      end
    end
  end

  describe '.add_to_wishlist' do
    context 'when movie is not in wishlist' do
      it 'adds movie to wishlist and returns success' do
        result = Wishlist.add_to_wishlist(user, movie.id)
        expect(result[:success]).to be true
        expect(result[:data][:message]).to eq("Movie added to wishlist")
        expect(result[:data][:movie_id]).to eq(movie.id)
        expect(result[:data][:is_wishlisted]).to be true
        expect(user.wishlists.find_by(movie: movie)).to be_present
      end

      it 'returns failure if movie does not exist' do
        result = Wishlist.add_to_wishlist(user, 9999)
        expect(result[:success]).to be false
        expect(result[:errors]).to eq(["Movie not found"])
      end
    end

    context 'when movie is already in wishlist' do
      before { create(:wishlist, user: user, movie: movie) }

      it 'removes movie from wishlist and returns success' do
        result = Wishlist.add_to_wishlist(user, movie.id)
        expect(result[:success]).to be true
        expect(result[:data][:message]).to eq("Movie removed from wishlist")
        expect(result[:data][:movie_id]).to eq(movie.id)
        expect(result[:data][:is_wishlisted]).to be false
        expect(user.wishlists.find_by(movie: movie)).to be_nil
      end
    end
  end

  describe '.remove_from_wishlist' do
    context 'when movie is in wishlist' do
      before { create(:wishlist, user: user, movie: movie) }

      it 'removes movie from wishlist and returns success' do
        result = Wishlist.remove_from_wishlist(user, movie.id)
        expect(result[:success]).to be true
        expect(result[:data][:message]).to eq("Movie removed from wishlist")
        expect(result[:data][:movie_id]).to eq(movie.id)
        expect(result[:data][:is_wishlisted]).to be false
        expect(user.wishlists.find_by(movie: movie)).to be_nil
      end
    end

    context 'when movie is not in wishlist' do
      it 'returns failure with error' do
        result = Wishlist.remove_from_wishlist(user, movie.id)
        expect(result[:success]).to be false
        expect(result[:errors]).to eq(["Movie not in wishlist"])
      end
    end
  end

  describe '.clear_wishlist' do
    context 'when user has wishlisted movies' do
      before do
        create(:wishlist, user: user, movie: movie)
        create(:wishlist, user: user, movie: another_movie)
      end

      it 'removes all movies from wishlist and returns success with count' do
        result = Wishlist.clear_wishlist(user)
        expect(result[:success]).to be true
        expect(result[:data][:message]).to eq("All wishlisted movies removed")
        expect(result[:data][:count]).to eq(2)
        expect(user.wishlists.count).to eq(0)
      end
    end

    context 'when user has no wishlisted movies' do
      it 'returns success with count 0' do
        result = Wishlist.clear_wishlist(user)
        expect(result[:success]).to be true
        expect(result[:data][:message]).to eq("All wishlisted movies removed")
        expect(result[:data][:count]).to eq(0)
      end
    end
  end

  describe '.wishlisted_movies' do
    context 'when user has wishlisted movies' do
      before do
        create(:wishlist, user: user, movie: movie)
        create(:wishlist, user: user, movie: another_movie)
      end

      it 'returns success with wishlisted movies' do
        result = Wishlist.wishlisted_movies(user)
        expect(result[:success]).to be true
        expect(result[:data].size).to eq(2)
        expect(result[:data].map { |m| m['id'] }).to include(movie.id, another_movie.id)
        expect(result[:data].map { |m| m['is_wishlisted'] }.uniq).to eq([true])
      end
    end

    context 'when user has no wishlisted movies' do
      it 'returns success with empty movies' do
        result = Wishlist.wishlisted_movies(user)
        expect(result[:success]).to be true
        expect(result[:data]).to be_empty
      end
    end
  end
end