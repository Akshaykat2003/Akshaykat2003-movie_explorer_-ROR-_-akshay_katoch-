require 'rails_helper'

RSpec.describe 'Api::V1::SubscriptionsController', type: :request do
  let(:user) { create(:user, role: 'user') }
  let(:token) { user.generate_jwt }
  let(:subscription) { create(:subscription, :gold, user: user, session_expires_at: 1.hour.from_now, expiry_date: 1.month.from_now) }

  describe 'POST /api/v1/subscriptions' do
    context 'with valid params (basic plan)' do
      it 'creates a basic subscription' do
        allow(SubscriptionPaymentService).to receive(:process_payment).and_return({
          success: true,
          subscription: create(:subscription, user: user, plan: 'basic', status: 'active')
        })
        post api_v1_subscriptions_path, params: { plan: 'basic' }, headers: { 'Authorization' => "Bearer #{token}" }
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['message']).to eq('Basic subscription created successfully')
      end
    end

    context 'with valid params (gold plan, web client)' do
      it 'creates a pending gold subscription with checkout URL' do
        allow(SubscriptionPaymentService).to receive(:process_payment).and_return({
          success: true,
          subscription: create(:subscription, :gold, user: user, session_expires_at: 1.hour.from_now, expiry_date: 1.month.from_now),
          session: OpenStruct.new(id: 'cs_test_123', url: 'https://checkout.example.com')
        })
        post api_v1_subscriptions_path, params: { plan: 'gold' }, headers: { 'Authorization' => "Bearer #{token}" }
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['session_id']).to eq('cs_test_123')
      end
    end

    context 'with valid params (gold plan, mobile client)' do
      it 'creates a pending gold subscription with client secret' do
        allow(SubscriptionPaymentService).to receive(:process_payment).and_return({
          success: true,
          subscription: create(:subscription, :gold, user: user, session_id: 'pi_test_123', session_expires_at: nil, expiry_date: 1.month.from_now),
          payment_intent: OpenStruct.new(client_secret: 'pi_xxx_secret_yyy'),
          amount: 499,
          currency: 'inr'
        })
        post api_v1_subscriptions_path,
             params: { plan: 'gold' },
             headers: { 'Authorization' => "Bearer #{token}", 'X-Client-Type' => 'mobile' }
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['client_secret']).to eq('pi_xxx_secret_yyy')
      end
    end

    context 'with invalid plan' do
      it 'returns an error' do
        post api_v1_subscriptions_path, params: { plan: 'invalid' }, headers: { 'Authorization' => "Bearer #{token}" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to eq(['Invalid plan. Must be one of: basic, gold, platinum'])
      end
    end
  end

  describe 'GET /api/v1/subscriptions/success' do
    context 'with valid session_id' do
      it 'completes the subscription payment' do
        subscription
        allow(SubscriptionPaymentService).to receive(:complete_payment).and_return({
          success: true,
          subscription: subscription
        })
        get api_v1_subscriptions_success_path, params: { session_id: subscription.session_id }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq('Subscription completed successfully')
      end
    end

    context 'with invalid session_id' do
      it 'returns an error' do
        allow(SubscriptionPaymentService).to receive(:complete_payment).and_return({
          success: false,
          error: 'Invalid session ID'
        })
        get api_v1_subscriptions_success_path, params: { session_id: 'invalid' }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to eq(['Invalid session ID'])
      end
    end
  end

  describe 'GET /api/v1/subscriptions/cancel' do
    context 'with valid session_id' do
      it 'cancels the subscription' do
        subscription
        get api_v1_subscriptions_cancel_path, params: { session_id: subscription.session_id }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq('Subscription cancelled successfully')
      end
    end
  end

  describe 'POST /api/v1/subscriptions/confirm_payment' do
    let(:subscription) { create(:subscription, :pending, user: user, session_id: 'pi_xxx', session_expires_at: nil, expiry_date: 1.month.from_now) }

    context 'with valid params' do
      it 'confirms the subscription payment' do
        allow(SubscriptionPaymentService).to receive(:complete_payment).and_return({
          success: true,
          subscription: subscription
        })
        post api_v1_subscriptions_confirm_payment_path,
             params: { payment_intent_id: 'pi_xxx', subscription_id: subscription.id },
             headers: { 'Authorization' => "Bearer #{token}" }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['message']).to eq('Subscription completed successfully')
      end
    end

    context 'with invalid params' do
      it 'returns an error for non-existent subscription' do
        post api_v1_subscriptions_confirm_payment_path,
             params: { payment_intent_id: 'pi_xxx', subscription_id: 9999 },
             headers: { 'Authorization' => "Bearer #{token}" }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['errors']).to eq(['Subscription not found or already processed'])
      end
    end
  end

  describe 'GET /api/v1/subscriptions/check_status' do
    context 'with an active subscription' do
      it 'returns the subscription status' do
        subscription
        get api_v1_subscriptions_check_status_path, headers: { 'Authorization' => "Bearer #{token}" }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['status']).to eq('pending')
      end
    end

    context 'without a subscription' do
      it 'returns a 404 error' do
        user_without_subscription = create(:user, role: 'user')
        token_without_subscription = user_without_subscription.generate_jwt
        get api_v1_subscriptions_check_status_path, headers: { 'Authorization' => "Bearer #{token_without_subscription}" }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['errors']).to eq(['Subscription not found'])
      end
    end
  end
end