# require 'rails_helper'

# RSpec.describe 'Api::V1::Users', type: :request do
#   describe 'POST /api/v1/signup' do
#     let(:valid_attributes) { attributes_for(:user) }

#     context 'when the request is valid' do
#       it 'creates a new user and returns 201' do
#         post '/api/v1/signup', params: valid_attributes
#         expect(response).to have_http_status(:created)
#         expect(JSON.parse(response.body)['message']).to eq('Signup successful')
#       end
#     end

#     context 'when the request is invalid' do
#       it 'returns validation errors' do
#         post '/api/v1/signup', params: { email: '' }  # Missing required fields
#         expect(response).to have_http_status(:unprocessable_entity)
#         expect(JSON.parse(response.body)).to have_key('errors')
#       end
#     end
#   end

#   describe 'POST /api/v1/login' do
#     let!(:user) { create(:user, password: 'password123') }

#     context 'when credentials are correct' do
#       it 'returns a JWT token' do
#         post '/api/v1/login', params: { email: user.email, password: 'password123' }
#         expect(response).to have_http_status(:ok)
#         expect(JSON.parse(response.body)).to have_key('token')
#       end
#     end

#     context 'when credentials are incorrect' do
#       it 'returns an unauthorized error' do
#         post '/api/v1/login', params: { email: user.email, password: 'wrongpassword' }
#         expect(response).to have_http_status(:unauthorized)
#         expect(JSON.parse(response.body)['error']).to eq('Invalid email or password')
#       end
#     end
#   end
# end
