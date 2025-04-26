require 'swagger_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  path '/api/v1/signup' do
    post('Signup user') do
      tags 'Users'
      consumes 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          first_name: { type: :string },
          last_name: { type: :string },
          email: { type: :string },
          password: { type: :string },
          mobile_number: { type: :string }
        },
        required: ['first_name', 'last_name', 'email', 'password', 'mobile_number']
      }

      response(201, 'User created successfully') do
        let(:user) { attributes_for(:user) }
        run_test!
      end

      response(422, 'Missing fields') do
        let(:user) { { email: 'test@example.com' } } # missing fields
        run_test!
      end

      response(422, 'Invalid email format') do
        let(:user) do
          attributes_for(:user).merge(email: 'invalid-email')
        end
        run_test!
      end
    end
  end

  path '/api/v1/login' do
    post('Login user') do
      tags 'Users'
      consumes 'application/json'
      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string },
          password: { type: :string }
        },
        required: ['email', 'password']
      }

      response(200, 'Login successful') do
        let!(:existing_user) { create(:user, password: 'password123') }
        let(:credentials) do
          {
            email: existing_user.email,
            password: 'password123'
          }
        end
        run_test!
      end

      response(401, 'Invalid credentials - wrong password') do
        let!(:existing_user) { create(:user, password: 'password123') }
        let(:credentials) do
          {
            email: existing_user.email,
            password: 'wrongpassword'
          }
        end
        run_test!
      end

      response(401, 'Invalid credentials - wrong email') do
        let(:credentials) do
          {
            email: 'nonexistent@example.com',
            password: 'somepassword'
          }
        end
        run_test!
      end

      response(401, 'Missing fields') do
        let(:credentials) { { email: nil, password: nil } } # missing both fields
        run_test!
      end
      
      response(401, 'Missing email') do
        let(:credentials) { { password: 'somepassword' } } # missing email
        run_test!
      end
      
      response(401, 'Missing password') do
        let(:credentials) { { email: 'test@example.com' } } # missing password
        run_test!
      end
    end
  end
end
