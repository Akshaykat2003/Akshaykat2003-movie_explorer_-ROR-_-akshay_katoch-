# require 'rails_helper'

# RSpec.describe BlacklistedToken, type: :model do
#   describe 'validations' do
#     it { should validate_presence_of(:token) }
#     it { should validate_presence_of(:expires_at) }
#     it { should validate_uniqueness_of(:token) }
#   end

#   describe '.blacklisted?' do
#     it 'returns true if the token is blacklisted' do
#       BlacklistedToken.create!(token: 'test_token', expires_at: 1.day.from_now)
#       expect(BlacklistedToken.blacklisted?('test_token')).to be true
#     end

#     it 'returns false if the token is not blacklisted' do
#       expect(BlacklistedToken.blacklisted?('unknown_token')).to be false
#     end
#   end

#   describe '.cleanup_expired' do
#     it 'deletes expired tokens' do
#       BlacklistedToken.create!(token: 'expired_token', expires_at: 1.day.ago)
#       BlacklistedToken.create!(token: 'valid_token', expires_at: 1.day.from_now)
#       expect { BlacklistedToken.cleanup_expired }.to change { BlacklistedToken.count }.by(-1)
#       expect(BlacklistedToken.exists?(token: 'expired_token')).to be false
#       expect(BlacklistedToken.exists?(token: 'valid_token')).to be true
#     end
#   end

#   describe '.blacklist' do
#     let(:user) { create(:user) }
#     let(:valid_token) { user.generate_jwt }
#     let(:expired_token) { JWT.encode({ user_id: user.id, exp: 1.day.ago.to_i }, Rails.application.credentials.secret_key_base) }

#     it 'blacklists a valid token successfully' do
#       result = BlacklistedToken.blacklist(valid_token, Rails.application.credentials.secret_key_base)
#       expect(result[:success]).to be true
#       expect(result[:message]).to eq('Logout successful')
#       expect(BlacklistedToken.exists?(token: valid_token)).to be true
#     end

#     it 'returns an error for a missing token' do
#       result = BlacklistedToken.blacklist(nil, Rails.application.credentials.secret_key_base)
#       expect(result[:success]).to be false
#       expect(result[:error]).to eq('Token is missing')
#     end

#     it 'returns an error for an already expired token' do
#       result = BlacklistedToken.blacklist(expired_token, Rails.application.credentials.secret_key_base)
#       expect(result[:success]).to be false
#       expect(result[:error]).to eq('Token already expired')
#     end

#     it 'returns an error for an invalid token' do
#       result = BlacklistedToken.blacklist('invalid_token', Rails.application.credentials.secret_key_base)
#       expect(result[:success]).to be false
#       expect(result[:error]).to eq('Invalid token')
#     end

#     it 'returns an error if the token is already blacklisted' do
#       BlacklistedToken.create!(token: valid_token, expires_at: 1.day.from_now)
#       result = BlacklistedToken.blacklist(valid_token, Rails.application.credentials.secret_key_base)
#       expect(result[:success]).to be false
#       expect(result[:error]).to include('Token has already been taken')
#     end
#   end
# end