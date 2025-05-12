require 'rails_helper'

RSpec.describe 'Api::V1::MoviesController', type: :request do
  let(:supervisor) { create(:user, role: 'supervisor') }
  let(:supervisor_token) { supervisor.generate_jwt }
  let(:movie) { create(:movie) }

  describe 'POST /api/v1/movies' do
    context 'with authorized user' do
      it 'returns forbidden error due to authorization failure' do
        post '/api/v1/movies', params: { title: 'New Movie', genre: 'Action', release_year: 2023, rating: 8.0, director: 'Director', duration: 120, description: 'A new movie', plan: 'basic' }, headers: { 'Authorization' => "Bearer #{supervisor_token}" }
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)['error']).to eq('Forbidden: You do not have permission to perform this action')
      end
    end

    context 'without authorization' do
      it 'returns forbidden error due to authorization failure' do
        post '/api/v1/movies', params: { title: 'New Movie', genre: 'Action', release_year: 2023, rating: 8.0, director: 'Director', duration: 120, description: 'A new movie', plan: 'basic' }
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)['error']).to eq('Forbidden: You do not have permission to perform this action')
      end
    end
  end

  describe 'PATCH /api/v1/movies/:id' do
    context 'with authorized user' do
      it 'returns forbidden error due to authorization failure' do
        patch "/api/v1/movies/#{movie.id}", params: { title: 'Updated Movie' }, headers: { 'Authorization' => "Bearer #{supervisor_token}" }
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)['error']).to eq('Forbidden: You do not have permission to perform this action')
      end
    end
  end

  describe 'DELETE /api/v1/movies/:id' do
    context 'with authorized user' do
      it 'returns forbidden error due to authorization failure' do
        delete "/api/v1/movies/#{movie.id}", headers: { 'Authorization' => "Bearer #{supervisor_token}" }
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)['error']).to eq('Forbidden: You do not have permission to perform this action')
      end
    end
  end
end