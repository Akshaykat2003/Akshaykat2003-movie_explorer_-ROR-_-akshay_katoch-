# spec/models/user_spec.rb

require 'rails_helper'

RSpec.describe User, type: :model do
  describe "Validations" do
    it "validates presence of first_name" do
      user = build(:user, first_name: nil) 
      expect(user.valid?).to eq(false)
      expect(user.errors[:first_name]).to include("can't be blank")
    end

    it "validates presence of last_name" do
      user = build(:user, last_name: nil) 
      expect(user.valid?).to eq(false)
      expect(user.errors[:last_name]).to include("can't be blank")
    end

    it "validates presence of email" do
      user = build(:user, email: nil) 
      expect(user.valid?).to eq(false)
      expect(user.errors[:email]).to include("can't be blank")
    end

    it "validates uniqueness of email" do
      create(:user, email: "test@example.com")
      duplicate_user = build(:user, email: "test@example.com")
      expect(duplicate_user.valid?).to eq(false)
      expect(duplicate_user.errors[:email]).to include("has already been taken")
    end

    it "validates email format" do
      user = build(:user, email: "invalid_email") 
      expect(user.valid?).to eq(false)
      expect(user.errors[:email]).to include("is invalid")
    end

    it "validates presence of password" do
      user = build(:user, password: nil) 
      expect(user.valid?).to eq(false)
      expect(user.errors[:password]).to include("can't be blank")
    end

    it "validates password length (minimum 6 characters)" do
      user = build(:user, password: "short") 
      expect(user.valid?).to eq(false)
      expect(user.errors[:password]).to include("is too short (minimum is 6 characters)")
    end

    it "validates mobile_number presence and length" do
      user = build(:user, mobile_number: nil) 
      expect(user.valid?).to eq(false)
      expect(user.errors[:mobile_number]).to include("can't be blank")
      user = build(:user, mobile_number: "123") 
      expect(user.valid?).to eq(false)
      expect(user.errors[:mobile_number]).to include("is the wrong length (should be 10 characters)")
    end

    it "validates mobile_number is numeric" do
      user = build(:user, mobile_number: "abcd123456") 
      expect(user.valid?).to eq(false)
      expect(user.errors[:mobile_number]).to include("is not a number")
    end

    it "validates inclusion of role in allowed values" do
      user = build(:user, role: "admin")
      expect(user.valid?).to eq(false)
      expect(user.errors[:role]).to include("is not included in the list")
    end
  end

  describe "Password" do
    it "requires a password_digest" do
      user = build(:user, password: nil) 
      expect(user.valid?).to eq(false)
      expect(user.errors[:password]).to include("can't be blank")
    end

    it "validates password length (minimum 6 characters)" do
      user = build(:user, password: "short") 
      expect(user.valid?).to eq(false)
      expect(user.errors[:password]).to include("is too short (minimum is 6 characters)")
    end
  end
end
