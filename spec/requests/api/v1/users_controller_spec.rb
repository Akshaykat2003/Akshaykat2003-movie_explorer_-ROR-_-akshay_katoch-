require 'rails_helper'

RSpec.describe 'Api::V1::UsersController', type: :request do
  let(:user) { create(:user, role: 'user', email: 'test@example.com', password: 'Password123') }
  let(:token) { user.generate_jwt }

  describe 'POST /api/v1/signup' do
    context 'with valid params' do
      it 'creates a new user and returns a token' do
        post '/api/v1/signup', params: {
          first_name: 'John',
          last_name: 'Doe',
          email: 'john.doe@example.com',
          password: 'Password123',
          mobile_number: '1234567890'
        }
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['message']).to eq('Signup successful')
        expect(JSON.parse(response.body)['token']).to be_present
        expect(JSON.parse(response.body)['user']['email']).to eq('john.doe@example.com')
      end
    end

    context 'with invalid params' do
      it 'returns an error for duplicate email' do
        create(:user, email: 'john.doe@example.com')
        post '/api/v1/signup', params: {
          first_name: 'John',
          last_name: 'Doe',
          email: 'john.doe@example.com',
          password: 'Password123',
          mobile_number: '1234567890'
        }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to include('Email has already been taken')
      end

      it 'returns an error for missing required fields' do
        post '/api/v1/signup', params: {
          first_name: 'John',
          email: 'john.doe@example.com'
        }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to include("Last name can't be blank")
        expect(JSON.parse(response.body)['errors']).to include("Password can't be blank")
        expect(JSON.parse(response.body)['errors']).to include("Mobile number can't be blank")
      end
    end
  end

  describe 'POST /api/v1/login' do
    context 'with valid credentials' do
      it 'returns an unauthorized error due to authentication failure' do
        post '/api/v1/login', params: {
          email: 'test@example.com',
          password: 'Password123'
        }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Invalid email or password')
      end
    end

    context 'with invalid credentials' do
      it 'returns an unauthorized error' do
        post '/api/v1/login', params: {
          email: 'test@example.com',
          password: 'WrongPassword'
        }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Invalid email or password')
      end

      it 'returns an unauthorized error for non-existent user' do
        post '/api/v1/login', params: {
          email: 'nonexistent@example.com',
          password: 'Password123'
        }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Invalid email or password')
      end
    end
  end

  describe 'POST /api/v1/logout' do
    context 'with valid authentication' do
      it 'logs out the user successfully' do
        post '/api/v1/logout', headers: { 'Authorization' => "Bearer #{token}" }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq('Logout successful')
      end
    end

    context 'without authentication' do
      it 'returns an unprocessable entity error' do
        post '/api/v1/logout'
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Token is required')
      end
    end
  end

  describe 'POST /api/v1/update_preferences' do
    context 'with valid authentication' do
      it 'returns unauthorized error due to authentication failure' do
        post '/api/v1/update_preferences', params: {
          device_token: 'fcm-device-token-here',
          notifications_enabled: true
        }, headers: { 'Authorization' => "Bearer #{token}" }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['errors']).to eq(['Authentication required'])
      end
    end

    context 'without authentication' do
      it 'returns an unauthorized error' do
        post '/api/v1/update_preferences', params: {
          device_token: 'fcm-device-token-here',
          notifications_enabled: true
        }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['errors']).to eq(['Authentication required'])
      end
    end
  end
end