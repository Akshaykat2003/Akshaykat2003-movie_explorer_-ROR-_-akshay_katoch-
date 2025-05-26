# spec/requests/api/v1/wishlists_spec.rb
require 'rails_helper'

RSpec.describe 'Api::V1::Wishlists', type: :request do
  let(:user) { create(:user) }
  let(:movie) { create(:movie) }
  let(:another_movie) { create(:movie, title: 'Another Movie') }
  let(:headers) { { 'Authorization' => "Bearer #{generate_jwt_token(user)}" } }

  # Define wishlist factory inline
  FactoryBot.define do
    factory :wishlist do
      user
      movie
    end
  end

  # Mock Cloudinary URLs
  before do
    allow_any_instance_of(Movie).to receive(:poster_url).and_return('http://example.com/poster.jpg')
    allow_any_instance_of(Movie).to receive(:banner_url).and_return('http://example.com/banner.jpg')
  end

  # Helper to generate JWT token (adjust based on your auth setup)
  def generate_jwt_token(user)
    payload = { user_id: user.id, exp: 24.hours.from_now.to_i }
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end

  describe 'POST /api/v1/wishlists' do
    context 'when authenticated and movie exists' do
      context 'when movie is not in wishlist' do
        it 'adds movie to wishlist and returns success' do
          post '/api/v1/wishlists', params: { movie_id: movie.id }, headers: headers
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq(
            'message' => 'Movie added to wishlist',
            'movie_id' => movie.id,
            'is_wishlisted' => true
          )
          expect(user.wishlists.count).to eq(1)
          expect(user.wishlists.first.movie_id).to eq(movie.id)
        end
      end

      context 'when movie is already in wishlist' do
        before { create(:wishlist, user: user, movie: movie) }

        it 'removes movie from wishlist and returns success' do
          post '/api/v1/wishlists', params: { movie_id: movie.id }, headers: headers
          expect(response).to have_http_status(:ok)
          expect(json_response).to eq(
            'message' => 'Movie removed from wishlist',
            'movie_id' => movie.id,
            'is_wishlisted' => false
          )
          expect(user.wishlists.count).to eq(0)
        end
      end
    end

    context 'when movie does not exist' do
      it 'returns not found with error' do
        post '/api/v1/wishlists', params: { movie_id: 999 }, headers: headers
        expect(response).to have_http_status(:not_found)
        expect(json_response).to eq('errors' => ['Movie not found'])
      end
    end

    context 'when validation fails' do
      before do
        allow_any_instance_of(Wishlist).to receive(:save).and_return(false)
        allow_any_instance_of(Wishlist).to receive(:errors).and_return(
          double(full_messages: ['Validation error'])
        )
      end

      it 'returns unprocessable entity with errors' do
        post '/api/v1/wishlists', params: { movie_id: movie.id }, headers: headers
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response).to eq('errors' => ['Validation error'])
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        post '/api/v1/wishlists', params: { movie_id: movie.id }
        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to include('error' => 'Not Authorized')
      end
    end
  end

  describe 'DELETE /api/v1/wishlists/:movie_id' do
    context 'when authenticated and movie is in wishlist' do
      before { create(:wishlist, user: user, movie: movie) }

      it 'removes movie from wishlist and returns success' do
        delete "/api/v1/wishlists/#{movie.id}", headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response).to eq(
          'message' => 'Movie removed from wishlist',
          'movie_id' => movie.id,
          'is_wishlisted' => false
        )
        expect(user.wishlists.count).to eq(0)
      end
    end

    context 'when movie is not in wishlist' do
      it 'returns not found with error' do
        delete "/api/v1/wishlists/#{movie.id}", headers: headers
        expect(response).to have_http_status(:not_found)
        expect(json_response).to eq('errors' => ['Movie not in wishlist'])
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        delete "/api/v1/wishlists/#{movie.id}"
        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to include('error' => 'Not Authorized')
      end
    end
  end

  describe 'DELETE /api/v1/wishlists/clear' do
    context 'when authenticated and wishlist has movies' do
      before do
        create(:wishlist, user: user, movie: movie)
        create(:wishlist, user: user, movie: another_movie)
      end

      it 'clears wishlist and returns success' do
        delete '/api/v1/wishlists/clear', headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response).to eq(
          'message' => 'All wishlisted movies removed',
          'count' => 2
        )
        expect(user.wishlists.count).to eq(0)
      end
    end

    context 'when wishlist is empty' do
      it 'returns success with count 0' do
        delete '/api/v1/wishlists/clear', headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response).to eq(
          'message' => 'All wishlisted movies removed',
          'count' => 0
        )
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        delete '/api/v1/wishlists/clear'
        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to include('error' => 'Not Authorized')
      end
    end
  end

  describe 'GET /api/v1/wishlists' do
    context 'when authenticated and wishlist has movies' do
      before do
        create(:wishlist, user: user, movie: movie)
        create(:wishlist, user: user, movie: another_movie)
      end

      it 'returns wishlisted movies' do
        get '/api/v1/wishlists', headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response).to be_an(Array)
        expect(json_response.size).to eq(2)

        movie_json = json_response.find { |m| m['id'] == movie.id }
        expect(movie_json).to include(
          'id' => movie.id,
          'title' => movie.title,
          'genre' => movie.genre,
          'release_year' => movie.release_year,
          'rating' => movie.rating,
          'director' => movie.director,
          'duration' => movie.duration,
          'description' => movie.description,
          'plan' => movie.plan,
          'poster_url' => 'http://example.com/poster.jpg',
          'banner_url' => 'http://example.com/banner.jpg',
          'is_wishlisted' => true
        )
      end
    end

    context 'when wishlist is empty' do
      it 'returns empty array' do
        get '/api/v1/wishlists', headers: headers
        expect(response).to have_http_status(:ok)
        expect(json_response).to eq([])
      end
    end

    context 'when not authenticated' do
      it 'returns unauthorized' do
        get '/api/v1/wishlists'
        expect(response).to have_http_status(:unauthorized)
        expect(json_response).to include('error' => 'Not Authorized')
      end
    end
  end

  # Helper to parse JSON response, handling HTML errors
  def json_response
    return {} if response.status == 404 && response.body.start_with?('<!DOCTYPE html>')
    JSON.parse(response.body)
  rescue JSON::ParserError
    {}
  end
end