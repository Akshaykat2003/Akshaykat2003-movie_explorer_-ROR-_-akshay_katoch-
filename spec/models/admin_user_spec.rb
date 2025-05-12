# spec/models/admin_user_spec.rb
require 'rails_helper'

RSpec.describe AdminUser, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      admin_user = create(:admin_user)
      expect(admin_user).to be_persisted
    end

    it 'is not valid without an email' do
      admin_user = build(:admin_user, email: nil)
      expect(admin_user).not_to be_valid
      expect(admin_user.errors[:email]).to include("can't be blank")
    end

    it 'is not valid without a password' do
      admin_user = build(:admin_user, password: nil)
      expect(admin_user).not_to be_valid
      expect(admin_user.errors[:password]).to include("can't be blank")
    end
  end
end