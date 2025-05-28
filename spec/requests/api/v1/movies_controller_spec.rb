# spec/requests/api/v1/movies_controller_spec.rb
require 'rails_helper'

RSpec.describe 'Api::V1::MoviesController', type: :request do
  let(:user) { create(:user, role: 'user') }
  let(:supervisor) { create(:user, role: 'supervisor') }
  let(:user_token) { user.generate_jwt }
  let(:supervisor_token) { supervisor.generate_jwt }
  let(:movie) { create(:movie, title: 'Original Movie', genre: 'Action', plan: 'basic') }
  let(:poster_file) { Rack::Test::UploadedFile.new(StringIO.new('poster content'), 'image/jpeg', original_filename: 'poster.jpg') }
  let(:banner_file) { Rack::Test::UploadedFile.new(StringIO.new('banner content'), 'image/jpeg', original_filename: 'banner.jpg') }

  describe 'GET /api/v1/movies' do
    let!(:movie1) { create(:movie, title: 'Movie One', genre: 'Action', release_year: 2023, rating: 8.0, plan: 'basic') }
    let!(:movie2) { create(:movie, title: 'Movie Two', genre: 'Drama', release_year: 2022, rating: 7.5, plan: 'gold') }

    before do
      expect(Movie.count).to eq(2), "Expected 2 movies to be created, got #{Movie.count}"
    end

    context 'without authentication' do
      it 'returns a list of movies with pagination' do
        get '/api/v1/movies', params: { page: 1 }
        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)
        expect(response_body['movies'].size).to eq(2)
        expect(response_body['movies'].first['title']).to eq('Movie One')
        expect(response_body['total_pages']).to eq(1)
        expect(response_body['current_page']).to eq(1)
      end

      it 'filters movies by search term' do
        get '/api/v1/movies', params: { search: 'One', page: 1 }
        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)
        expect(response_body['movies'].size).to eq(1)
        expect(response_body['movies'].first['title']).to eq('Movie One')
      end

      it 'filters movies by genre' do
        get '/api/v1/movies', params: { genre: 'Action', page: 1 }
        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)
        expect(response_body['movies'].size).to eq(1)
        expect(response_body['movies'].first['genre']).to eq('Action')
      end

      it 'filters movies by release year' do
        get '/api/v1/movies', params: { release_year: 2023, page: 1 }
        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)
        expect(response_body['movies'].size).to eq(1)
        expect(response_body['movies'].first['release_year']).to eq(2023)
      end

      it 'filters movies by rating' do
        get '/api/v1/movies', params: { rating: 8.0, page: 1 }
        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)
        expect(response_body['movies'].size).to eq(1)
        expect(response_body['movies'].first['rating']).to eq(8.0)
      end

      it 'handles invalid page numbers gracefully' do
        get '/api/v1/movies', params: { page: -1 }
        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)
        expect(response_body['current_page']).to eq(1)
      end
    end

    context 'with authentication' do
      it 'returns a list of movies for an authenticated user' do
        get '/api/v1/movies', params: { page: 1 }, headers: { 'Authorization' => "Bearer #{supervisor_token}" }
        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)
        expect(response_body['movies'].size).to eq(2)
      end
    end
  end

  describe 'GET /api/v1/movies/all' do
    let!(:movie1) { create(:movie, title: 'Movie One') }
    let!(:movie2) { create(:movie, title: 'Movie Two') }

    before do
      expect(Movie.count).to eq(2), "Expected 2 movies to be created, got #{Movie.count}"
    end

    context 'without authentication' do
      it 'returns all movies without pagination' do
        get '/api/v1/movies/all'
        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)
        expect(response_body['movies'].size).to eq(2)
        expect(response_body['movies'].map { |m| m['title'] }).to include('Movie One', 'Movie Two')
      end
    end

    context 'with authentication' do
      it 'returns all movies for an authenticated user' do
        get '/api/v1/movies/all', headers: { 'Authorization' => "Bearer #{supervisor_token}" }
        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)
        expect(response_body['movies'].size).to eq(2)
      end
    end
  end

  describe 'GET /api/v1/movies/:id' do
    context 'when the movie exists' do
      it 'returns the movie details with authentication' do
        get "/api/v1/movies/#{movie.id}", headers: { 'Authorization' => "Bearer #{supervisor_token}" }
        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)
        expect(response_body['id']).to eq(movie.id)
        expect(response_body['title']).to eq('Original Movie')
      end
    end

    context 'when the movie does not exist' do
      it 'returns a 404 error with authentication' do
        get '/api/v1/movies/9999', headers: { 'Authorization' => "Bearer #{supervisor_token}" }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['errors']).to eq(['Movie not found'])
      end
    end

    context 'without authentication' do
      it 'returns an unauthorized error' do
        get "/api/v1/movies/#{movie.id}"
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['errors']).to eq(['Unauthorized: Missing token'])
      end
    end
  end

  describe 'POST /api/v1/movies' do
    let(:valid_params) do
      {
        title: 'New Movie',
        genre: 'Action',
        release_year: 2023,
        rating: 8.0,
        director: 'Director',
        duration: 120,
        description: 'A new movie',
        plan: 'basic',
        poster: poster_file,
        banner: banner_file
      }
    end

    context 'with authorized user (supervisor)' do
      before do
        allow_any_instance_of(Movie).to receive(:send_new_movie_notification).and_return(true)
        allow_any_instance_of(ActiveStorage::Blob).to receive(:key).and_return('poster_key')
        allow(Cloudinary::Utils).to receive(:cloudinary_url).and_return('http://cloudinary.com/poster.jpg')
      end

      # it 'creates a new movie successfully' do
      #   expect {
      #     post '/api/v1/movies',
      #          params: valid_params,
      #          headers: { 'Authorization' => "Bearer #{supervisor_token}" }
      #   }.to change(Movie, :count).by(1)
      #   expect(response).to have_http_status(:created)
      #   response_body = JSON.parse(response.body)
      #   expect(response_body['title']).to eq('New Movie')
      #   expect(response_body['genre']).to eq('Action')
      #   expect(response_body['plan']).to eq('basic')
      #   expect(response_body['poster_url']).to eq('http://cloudinary.com/poster.jpg')
      #   expect(response_body['banner_url']).to eq('http://cloudinary.com/poster.jpg')
      #   expect(Movie.last.poster.attached?).to be true
      #   expect(Movie.last.banner.attached?).to be true
      # end

      it 'creates a movie without poster and banner' do
        post '/api/v1/movies',
             params: valid_params.except(:poster, :banner),
             headers: { 'Authorization' => "Bearer #{supervisor_token}" }
        expect(response).to have_http_status(:created)
        response_body = JSON.parse(response.body)
        expect(response_body['title']).to eq('New Movie')
        expect(response_body['poster_url']).to be_nil
        expect(response_body['banner_url']).to be_nil
        expect(Movie.last.poster.attached?).to be false
        expect(Movie.last.banner.attached?).to be false
      end

      it 'returns validation errors for invalid params' do
        post '/api/v1/movies',
             params: { title: '', genre: 'Action', release_year: 2023, rating: 8.0, director: 'Director', duration: 120, description: 'A new movie', plan: 'basic' },
             headers: { 'Authorization' => "Bearer #{supervisor_token}" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to include("Title can't be blank")
      end
    end

    context 'with unauthorized user (non-supervisor)' do
      it 'returns a forbidden error' do
        post '/api/v1/movies',
             params: valid_params,
             headers: { 'Authorization' => "Bearer #{user_token}" }
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)['errors']).to eq(['Forbidden: You do not have permission to perform this action'])
      end
    end

    context 'without authentication' do
      it 'returns an unauthorized error' do
        post '/api/v1/movies', params: valid_params
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['errors']).to eq(['Unauthorized: Missing token'])
      end
    end
  end

  describe 'PATCH /api/v1/movies/:id' do
    let(:update_params) do
      {
        title: 'Updated Movie',
        genre: 'Drama',
        release_year: 2024,
        rating: 9.0,
        director: 'New Director',
        duration: 150,
        description: 'Updated description',
        plan: 'gold'
      }
    end

    context 'with authorized user' do
      before do
        allow_any_instance_of(ActiveStorage::Blob).to receive(:key).and_return('poster_key')
        allow(Cloudinary::Utils).to receive(:cloudinary_url).and_return('http://cloudinary.com/poster.jpg')
      end

      it 'should update the movie successfully' do
        patch "/api/v1/movies/#{movie.id}",
              params: update_params,
              headers: { 'Authorization' => "Bearer #{supervisor_token}" }
        expect(response).to have_http_status(:ok)
        response_body = JSON.parse(response.body)
        expect(response_body['title']).to eq('Updated Movie')
        expect(response_body['genre']).to eq('Drama')
        expect(response_body['plan']).to eq('gold')
      end

      # it 'updates the movie with new poster and banner' do
      #   expect_any_instance_of(Movie).to receive(:poster).twice.and_call_original
      #   expect_any_instance_of(Movie).to receive(:banner).twice.and_call_original
      #   patch "/api/v1/movies/#{movie.id}",
      #         params: { poster: poster_file, banner: banner_file },
      #         headers: { 'Authorization' => "Bearer #{supervisor_token}" }
      #   expect(response).to have_http_status(:ok)
      #   response_body = JSON.parse(response.body)
      #   expect(response_body['poster_url']).to eq('http://cloudinary.com/poster.jpg')
      #   expect(response_body['banner_url']).to eq('http://cloudinary.com/poster.jpg')
      #   movie.reload
      #   expect(movie.poster.attached?).to be true
      #   expect(movie.banner.attached?).to be true
      # end

      it 'returns validation errors for invalid params' do
        patch "/api/v1/movies/#{movie.id}",
              params: { title: '', genre: 'Action', release_year: 2023, rating: 8.0, director: 'Director', duration: 120, description: 'A new movie', plan: 'basic' },
              headers: { 'Authorization' => "Bearer #{supervisor_token}" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to include("Title can't be blank")
      end

      it 'returns a 404 error for a non-existent movie' do
        patch '/api/v1/movies/9999',
              params: update_params,
              headers: { 'Authorization' => "Bearer #{supervisor_token}" }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['errors']).to eq(['Movie not found'])
      end
    end

    context 'with unauthorized user (non-supervisor)' do
      it 'returns a forbidden error' do
        patch "/api/v1/movies/#{movie.id}",
              params: update_params,
              headers: { 'Authorization' => "Bearer #{user_token}" }
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)['errors']).to eq(['Forbidden: You do not have permission to perform this action'])
      end
    end

    context 'without authentication' do
      it 'returns an unauthorized error' do
        patch "/api/v1/movies/#{movie.id}", params: update_params
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['errors']).to eq(['Unauthorized: Missing token'])
      end
    end
  end

  describe 'DELETE /api/v1/movies/:id' do
    context 'with authorized user (supervisor)' do
      it 'deletes the movie successfully' do
        delete "/api/v1/movies/#{movie.id}",
               headers: { 'Authorization' => "Bearer #{supervisor_token}" }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq('Movie deleted successfully')
        expect { movie.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'returns a 404 error for a non-existent movie' do
        delete '/api/v1/movies/9999',
               headers: { 'Authorization' => "Bearer #{supervisor_token}" }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['errors']).to eq(['Movie not found'])
      end
    end

    context 'with unauthorized user (non-supervisor)' do
      it 'returns a forbidden error' do
        delete "/api/v1/movies/#{movie.id}",
               headers: { 'Authorization' => "Bearer #{user_token}" }
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)['errors']).to eq(['Forbidden: You do not have permission to perform this action'])
      end
    end

    context 'without authentication' do
      it 'returns an unauthorized error' do
        delete "/api/v1/movies/#{movie.id}"
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['errors']).to eq(['Unauthorized: Missing token'])
      end
    end
  end
end
