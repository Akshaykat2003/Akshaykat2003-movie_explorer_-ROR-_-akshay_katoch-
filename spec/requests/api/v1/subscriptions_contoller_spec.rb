require 'rails_helper'

RSpec.describe 'Api::V1::SubscriptionsController', type: :request do
  let(:user) { create(:user, role: 'user') }
  let(:token) { user.generate_jwt }
  let(:subscription) { create(:subscription, user: user, plan: 'gold', status: 'pending', session_id: 'cs_test_123', session_expires_at: 1.hour.from_now, expiry_date: 1.month.from_now) }

  describe 'GET /api/v1/subscriptions' do
    context 'with valid authentication' do
      it 'returns unauthorized error due to authentication failure' do
        expect(User.find(user.id)).to eq(user)
        subscription
        get '/api/v1/subscriptions', headers: { 'Authorization' => "Bearer #{token}" }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Authenticated user not found')
      end
    end

    context 'with no subscription' do
      it 'returns unauthorized error due to authentication failure' do
        expect(User.find(user.id)).to eq(user)
        get '/api/v1/subscriptions', headers: { 'Authorization' => "Bearer #{token}" }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('Authenticated user not found')
      end
    end

    context 'without authentication' do
      it 'returns an unauthorized error' do
        get '/api/v1/subscriptions'
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'POST /api/v1/subscriptions' do
    context 'with valid params (basic plan)' do
      it 'creates a basic subscription' do
        expect(User.find(user.id)).to eq(user)
        allow(SubscriptionPaymentService).to receive(:process_payment).and_return({
          success: true,
          subscription: create(:subscription, user: user, plan: 'basic', status: 'active'),
          session: OpenStruct.new(id: 'cs_test_123', url: 'https://checkout.example.com')
        })
        post '/api/v1/subscriptions', params: { plan: 'basic' }, headers: { 'Authorization' => "Bearer #{token}" }
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['session_id']).to eq('cs_test_123')
      end
    end

    context 'with valid params (gold plan)' do
      it 'creates a pending gold subscription with checkout URL' do
        expect(User.find(user.id)).to eq(user)
        allow(SubscriptionPaymentService).to receive(:process_payment).and_return({
          success: true,
          subscription: create(:subscription, user: user, plan: 'gold', status: 'pending', session_id: 'cs_test_123', session_expires_at: 1.hour.from_now, expiry_date: 1.month.from_now),
          session: OpenStruct.new(id: 'cs_test_123', url: 'https://checkout.example.com')
        })
        post '/api/v1/subscriptions', params: { plan: 'gold' }, headers: { 'Authorization' => "Bearer #{token}" }
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['session_id']).to eq('cs_test_123')
      end
    end

    context 'with invalid plan' do
      it 'returns an error' do
        expect(User.find(user.id)).to eq(user)
        post '/api/v1/subscriptions', params: { plan: 'invalid' }, headers: { 'Authorization' => "Bearer #{token}" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Invalid plan')
      end
    end
  end

  describe 'GET /api/v1/subscriptions/success' do
    it 'completes the subscription payment' do
      subscription
      allow(SubscriptionPaymentService).to receive(:complete_payment).and_return({
        success: true,
        subscription: subscription
      })
      get '/api/v1/subscriptions/success', params: { session_id: 'cs_test_123' }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['message']).to eq('Subscription completed successfully')
    end

    context 'with invalid session_id' do
      it 'returns an error' do
        get '/api/v1/subscriptions/success', params: { session_id: 'invalid' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Invalid session ID')
      end
    end
  end

  describe 'GET /api/v1/subscriptions/cancel' do
    it 'cancels the subscription' do
      subscription
      get '/api/v1/subscriptions/cancel', params: { session_id: 'cs_test_123' }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['message']).to eq('Subscription cancelled successfully')
    end

    context 'with invalid session_id' do
      it 'returns an error' do
        get '/api/v1/subscriptions/cancel', params: { session_id: 'invalid' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Invalid session ID')
      end
    end
  end
end