
require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(user).to be_persisted
    end

    it 'is not valid without a first_name' do
      user.first_name = nil
      expect(user).not_to be_valid
      expect(user.errors[:first_name]).to include("can't be blank")
    end

    it 'is not valid without a last_name' do
      user.last_name = nil
      expect(user).not_to be_valid
      expect(user.errors[:last_name]).to include("can't be blank")
    end

    it 'is not valid without an email' do
      user.email = nil
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it 'is not valid with an invalid email format' do
      user.email = 'invalid-email'
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('is invalid')
    end

    it 'is not valid with a duplicate email' do
      duplicate_user = build(:user, email: user.email)
      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:email]).to include('has already been taken')
    end

    it 'is not valid without a mobile_number' do
      user.mobile_number = nil
      expect(user).not_to be_valid
      expect(user.errors[:mobile_number]).to include("can't be blank")
    end

    it 'is not valid with a mobile_number that is not 10 digits' do
      user.mobile_number = '12345'
      expect(user).not_to be_valid
      expect(user.errors[:mobile_number]).to include('is the wrong length (should be 10 characters)')
    end

    it 'is not valid without a role' do
      user.role = nil
      expect(user).not_to be_valid
      expect(user.errors[:role]).to include("can't be blank")
    end

    it 'is not valid with an invalid role' do
      user.role = 'invalid'
      expect(user).not_to be_valid
      expect(user.errors[:role]).to include('is not included in the list')
    end
  end

  describe 'associations' do
    it 'has one subscription' do
      subscription = create(:subscription, user: user)
      expect(user.subscription).to eq(subscription)
    end
  end

  describe '.register' do
    it 'creates a user with role user' do
      params = {
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        email: Faker::Internet.unique.email,
        mobile_number: Faker::Number.number(digits: 10).to_s,
        password: 'password123'
      }
      result = User.register(params)
      expect(result[:success]).to be true
      expect(result[:user].role).to eq('user')
    end
  end

  describe '.authenticate' do
    # it 'returns the user if credentials are correct' do
    #   authenticated_user = User.authenticate(user.email, 'password123')
    #   expect(authenticated_user).to eq(user)
    # end

    it 'returns nil if credentials are incorrect' do
      authenticated_user = User.authenticate(user.email, 'wrongpassword')
      expect(authenticated_user).to be_nil
    end
  end

  describe '#generate_jwt' do
    it 'generates a valid JWT token' do
      token = user.generate_jwt
      decoded = JWT.decode(token, Rails.application.credentials.secret_key_base, true, algorithm: 'HS256')
      expect(decoded.first['user_id']).to eq(user.id)
    end
  end

  describe '.decode_jwt' do
    it 'decodes a valid JWT token and returns the user' do
      token = user.generate_jwt
      decoded_user = User.decode_jwt(token)
      expect(decoded_user).to eq(user)
    end

    it 'returns nil for an invalid token' do
      decoded_user = User.decode_jwt('invalid.token')
      expect(decoded_user).to be_nil
    end
  end

  describe '#as_json_with_plan' do
    it 'includes the active plan in the JSON output if subscription is active' do
      create(:subscription, user: user, status: 'active', plan: 'basic')
      user.reload 
      json = user.as_json_with_plan
      expect(json['active_plan']).to eq('basic')
    end

    it 'returns basic for active_plan if no active subscription exists' do
      user.subscription&.destroy
      user.reload
      json = user.as_json_with_plan
      expect(json['active_plan']).to eq('basic')
    end
  end
end