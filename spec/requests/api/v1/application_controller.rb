require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  describe '#authenticate_admin_user!' do
    it 'returns true' do
      expect(controller.authenticate_admin_user!).to be true
    end
  end

  describe '#current_admin_user' do
    it 'returns nil' do
      expect(controller.current_admin_user).to be_nil
    end
  end

  describe '#active_admin_controller?' do
    context 'when controller path starts with admin/' do
      before do
        allow(controller).to receive(:controller_path).and_return('admin/users')
      end

      it 'returns true' do
        expect(controller.send(:active_admin_controller?)).to be true
      end
    end

    context 'when controller path does not start with admin/' do
      before do
        allow(controller).to receive(:controller_path).and_return('api/v1/users')
      end

      it 'returns false' do
        expect(controller.send(:active_admin_controller?)).to be false
      end
    end
  end

  describe '#authenticate_request' do
    context 'with a valid token' do
      let(:user) { create(:user) }
      let(:token) { user.generate_jwt }

      it 'sets the current user' do
        request.headers['Authorization'] = "Bearer #{token}"
        controller.send(:authenticate_request)
        expect(assigns(:current_user)).to eq(user)
      end
    end

    context 'with a missing token' do
      it 'returns an unauthorized error' do
        request.headers['Authorization'] = nil
        controller.send(:authenticate_request)
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['errors']).to eq(['Unauthorized: Missing token'])
      end
    end

    context 'with an invalid token' do
      it 'returns an unauthorized error' do
        request.headers['Authorization'] = 'Bearer invalid_token'
        controller.send(:authenticate_request)
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['errors']).to match_array(['Unauthorized: Invalid token - Not enough or too many segments'])
      end
    end

    context 'with a non-existent user' do
      let(:token) { JWT.encode({ user_id: 9999 }, Rails.application.credentials.secret_key_base) }

      it 'returns an unauthorized error' do
        request.headers['Authorization'] = "Bearer #{token}"
        controller.send(:authenticate_request)
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['errors']).to eq(['Unauthorized: User not found'])
      end
    end

    context 'with a StandardError' do
      before do
        allow(JWT).to receive(:decode).and_raise(StandardError.new('Unexpected error'))
      end

      it 'returns an internal server error' do
        request.headers['Authorization'] = 'Bearer some_token'
        controller.send(:authenticate_request)
        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)['errors']).to eq(['Internal server error'])
      end
    end
  end
end