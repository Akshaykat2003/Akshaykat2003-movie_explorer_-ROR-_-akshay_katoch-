# # spec/models/blacklisted_token_spec.rb
# require 'rails_helper'

# RSpec.describe BlacklistedToken, type: :model do
#   let(:token) { 'sample.token.value' }

#   describe 'validations' do
#     it 'is valid with a token' do
#       blacklisted_token = BlacklistedToken.create(token: token)
#       expect(blacklisted_token).to be_persisted
#     end

#     it 'is not valid without a token' do
#       blacklisted_token = BlacklistedToken.create(token: nil)
#       expect(blacklisted_token).not_to be_valid
#       expect(blacklisted_token.errors[:token]).to include("can't be blank")
#     end

#     it 'is not valid with a duplicate token' do
#       BlacklistedToken.create(token: token)
#       duplicate_token = BlacklistedToken.create(token: token)
#       expect(duplicate_token).not_to be_valid
#       expect(duplicate_token.errors[:token]).to include('has already been taken')
#     end
#   end

#   describe '.blacklist' do
#     it 'blacklists a token successfully' do
#       result = BlacklistedToken.blacklist(token, Rails.application.credentials.secret_key_base)
#       expect(result[:success]).to be true
#       expect(result[:message]).to eq('Logout successful')
#     end

#     it 'returns an error if token is blank' do
#       result = BlacklistedToken.blacklist(nil, Rails.application.credentials.secret_key_base)
#       expect(result[:success]).to be false
#       expect(result[:error]).to eq('Authorization header missing')
#     end
#   end

#   describe '.blacklisted?' do
#     it 'returns true if token is blacklisted' do
#       BlacklistedToken.create(token: token)
#       expect(BlacklistedToken.blacklisted?(token)).to be true
#     end

#     it 'returns false if token is not blacklisted' do
#       expect(BlacklistedToken.blacklisted?(token)).to be false
#     end
#   end
# end