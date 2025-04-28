# require 'rails_helper'

# RSpec.describe 'Movies API', type: :request, swagger_doc: 'v1/swagger.yaml' do
#   let(:supervisor) { create(:user, role: 'supervisor') }
#   let(:jwt_token) { supervisor.generate_jwt }
#   let(:headers) { { 'Authorization' => "Bearer #{jwt_token}", 'Content-Type' => 'application/json' } }

#   path '/api/v1/movies' do
#     post 'Create a movie' do
#       tags 'Movies'
#       consumes 'application/json'
#       produces 'application/json'
#       security [bearerAuth: []]
#       parameter name: :movie, in: :body, schema: {
#         type: :object,
#         properties: {
#           movie: {
#             type: :object,
#             properties: {
#               title: { type: :string },
#               genre: { type: :string },
#               release_year: { type: :integer },
#               rating: { type: :number }
#             },
#             required: ['title', 'genre']
#           }
#         },
#         required: ['movie']
#       }

#       response '201', 'Movie created successfully' do
#         let(:movie) { { movie: { title: 'Inception', genre: 'Sci-Fi', release_year: 2010, rating: 8.8 } } }
#         before { post '/api/v1/movies', params: movie.to_json, headers: headers }
#         run_test!
#       end

#       response '422', 'Validation errors' do
#         let(:movie) { { movie: { title: '', genre: '' } } }
#         before { post '/api/v1/movies', params: movie.to_json, headers: headers }
#         run_test!
#       end
#     end
#   end

#   path '/api/v1/movies/{id}' do
#     let(:movie) { create(:movie, title: 'Inception', genre: 'Sci-Fi') }

#     put 'Update a movie' do
#       tags 'Movies'
#       consumes 'application/json'
#       produces 'application/json'
#       security [bearerAuth: []]
#       parameter name: :id, in: :path, type: :integer
#       parameter name: :movie, in: :body, schema: {
#         type: :object,
#         properties: {
#           movie: {
#             type: :object,
#             properties: {
#               title: { type: :string },
#               genre: { type: :string },
#               release_year: { type: :integer },
#               rating: { type: :number }
#             }
#           }
#         }
#       }

#       response '200', 'Movie updated successfully' do
#         let(:id) { movie.id }
#         let(:movie_params) { { movie: { title: 'Inception Updated', genre: 'Sci-Fi' } } }
#         before { put "/api/v1/movies/#{id}", params: movie_params.to_json, headers: headers }
#         run_test!
#       end

#       response '422', 'Invalid input' do
#         let(:id) { movie.id }
#         let(:movie_params) { { movie: { title: '' } } }
#         before { put "/api/v1/movies/#{id}", params: movie_params.to_json, headers: headers }
#         run_test!
#       end
#     end

#     delete 'Delete a movie' do
#       tags 'Movies'
#       produces 'application/json'
#       security [bearerAuth: []]
#       parameter name: :id, in: :path, type: :integer

#       response '200', 'Movie deleted successfully' do
#         let(:id) { movie.id }
#         before { delete "/api/v1/movies/#{id}", headers: headers }
#         run_test!
#       end
#     end
#   end
# end