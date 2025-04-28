# require 'rails_helper'

# RSpec.describe 'Movies API', type: :request do
#   let(:admin_user) { create(:user, role: 'admin') }
#   let(:supervisor_user) { create(:user, role: 'supervisor') }
#   let(:user) { create(:user, role: 'user') }
#   let(:movie) { create(:movie) }  
  
  
#   def login(user)
#     post '/api/v1/auth/sign_in', params: { email: user.email, password: 'password123' }
#     json_response = JSON.parse(response.body)
#     json_response['data']['auth_token']
#   end

#   describe 'GET /api/v1/movies' do
#     it 'returns a list of movies with pagination' do
#       create_list(:movie, 20)  
#       auth_token = login(admin_user)  

#       get '/api/v1/movies', params: { page: 1 }, headers: { 'Authorization' => "Bearer #{auth_token}" }

#       expect(response).to have_http_status(:ok)
#       json_response = JSON.parse(response.body)
#       expect(json_response['movies'].size).to eq(10) 
#       expect(json_response['total_pages']).to be > 1
#     end
#   end

#   describe 'GET /api/v1/movies/:id' do
#     it 'returns the movie details' do
#       auth_token = login(admin_user)  
#       get "/api/v1/movies/#{movie.id}", headers: { 'Authorization' => "Bearer #{auth_token}" }

#       expect(response).to have_http_status(:ok)
#       json_response = JSON.parse(response.body)
#       expect(json_response['id']).to eq(movie.id)
#     end

#     it 'returns an error if movie is not found' do
#       auth_token = login(admin_user)  # Login as admin
#       get '/api/v1/movies/9999', headers: { 'Authorization' => "Bearer #{auth_token}" }

#       expect(response).to have_http_status(:not_found)
#       json_response = JSON.parse(response.body)
#       expect(json_response['error']).to eq('Movie not found')
#     end
#   end

#   describe 'POST /api/v1/movies' do
#     context 'when user is admin or supervisor' do
#       it 'creates a new movie' do
#         movie_params = { title: 'Inception', genre: 'Sci-Fi', release_year: 2010, rating: 8.8, director: 'Christopher Nolan' }
#         auth_token = login(admin_user)  # Login as admin

#         post '/api/v1/movies', params: movie_params, headers: { 'Authorization' => "Bearer #{auth_token}" }

#         expect(response).to have_http_status(:created)
#         json_response = JSON.parse(response.body)
#         expect(json_response['title']).to eq('Inception')
#       end
#     end

#     context 'when user is not admin or supervisor' do
#       it 'forbids the action' do
#         movie_params = { title: 'Inception', genre: 'Sci-Fi', release_year: 2010, rating: 8.8 }
#         auth_token = login(user)  # Login as a normal user

#         post '/api/v1/movies', params: movie_params, headers: { 'Authorization' => "Bearer #{auth_token}" }

#         expect(response).to have_http_status(:forbidden)
#         json_response = JSON.parse(response.body)
#         expect(json_response['error']).to eq('Forbidden: You do not have permission to perform this action')
#       end
#     end
#   end

#   describe 'PATCH /api/v1/movies/:id' do
#     context 'when user is admin or supervisor' do
#       it 'updates the movie' do
#         updated_params = { title: 'Updated Title' }
#         auth_token = login(admin_user)  # Login as admin

#         patch "/api/v1/movies/#{movie.id}", params: updated_params, headers: { 'Authorization' => "Bearer #{auth_token}" }

#         expect(response).to have_http_status(:ok)
#         json_response = JSON.parse(response.body)
#         expect(json_response['title']).to eq('Updated Title')
#       end
#     end

#     context 'when user is not authorized' do
#       it 'forbids the action' do
#         updated_params = { title: 'Updated Title' }
#         auth_token = login(user)  # Login as normal user

#         patch "/api/v1/movies/#{movie.id}", params: updated_params, headers: { 'Authorization' => "Bearer #{auth_token}" }

#         expect(response).to have_http_status(:forbidden)
#         json_response = JSON.parse(response.body)
#         expect(json_response['error']).to eq('Forbidden: You do not have permission to perform this action')
#       end
#     end
#   end

#   describe 'DELETE /api/v1/movies/:id' do
#     context 'when user is admin or supervisor' do
#       it 'deletes the movie' do
#         auth_token = login(admin_user)  # Login as admin

#         delete "/api/v1/movies/#{movie.id}", headers: { 'Authorization' => "Bearer #{auth_token}" }

#         expect(response).to have_http_status(:no_content)
#       end
#     end

#     context 'when user is not authorized' do
#       it 'forbids the action' do
#         auth_token = login(user)  # Login as normal user

#         delete "/api/v1/movies/#{movie.id}", headers: { 'Authorization' => "Bearer #{auth_token}" }

#         expect(response).to have_http_status(:forbidden)
#         json_response = JSON.parse(response.body)
#         expect(json_response['error']).to eq('Forbidden: You do not have permission to perform this action')
#       end
#     end
#   end
# end
