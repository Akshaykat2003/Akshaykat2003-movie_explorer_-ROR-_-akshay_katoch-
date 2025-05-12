# spec/models/subscription_spec.rb
require 'rails_helper'

RSpec.describe Subscription, type: :model do
  describe 'validations' do
    let(:subscription) { create(:subscription) }

    it 'is valid with valid attributes' do
      expect(subscription).to be_persisted
    end

    it 'is not valid without a user' do
      subscription.user = nil
      expect(subscription).not_to be_valid
      expect(subscription.errors[:user]).to include("must exist")
    end

    it 'is not valid without a plan' do
      subscription.plan = nil
      expect(subscription).not_to be_valid
      expect(subscription.errors[:plan]).to include("can't be blank")
    end

    it 'is not valid with an invalid plan' do
      subscription = build(:subscription, plan: nil) # Reset plan to nil to trigger validation
      subscription.assign_attributes(plan: 'invalid') # Use assign_attributes to avoid ArgumentError
      expect(subscription).not_to be_valid
      expect(subscription.errors[:plan]).to include('is not a valid plan')
    end

    it 'is not valid without a status' do
      subscription.status = nil
      expect(subscription).not_to be_valid
      expect(subscription.errors[:status]).to include("can't be blank")
    end

    it 'is not valid with an invalid status' do
      subscription = build(:subscription, status: nil) # Reset status to nil to trigger validation
      subscription.assign_attributes(status: 'invalid') # Use assign_attributes to avoid ArgumentError
      expect(subscription).not_to be_valid
      expect(subscription.errors[:status]).to include('is not a valid status')
    end

    it 'is not valid without session_expires_at if pending' do
      subscription = build(:subscription, :gold, session_expires_at: nil)
      expect(subscription).not_to be_valid
      expect(subscription.errors[:session_expires_at]).to include("can't be blank")
    end
  end

  describe '#expired?' do
    it 'returns false for a basic plan' do
      subscription = create(:subscription, plan: 'basic')
      expect(subscription.expired?).to be false
    end

    it 'returns true for a gold plan past expiry' do
      subscription = create(:subscription, :gold, session_expires_at: 30.minutes.from_now, expiry_date: Time.current - 1.day)
      expect(subscription.expired?).to be true
    end

    it 'returns false for a gold plan not yet expired' do
      subscription = create(:subscription, :gold, session_expires_at: 30.minutes.from_now, expiry_date: Time.current + 1.day)
      expect(subscription.expired?).to be false
    end
  end

  describe '#active?' do
    it 'returns true for an active basic plan' do
      subscription = create(:subscription, plan: 'basic', status: 'active')
      expect(subscription.active?).to be true
    end

    it 'downgrades to basic if expired and returns true' do
      subscription = create(:subscription, :gold, status: 'active', expiry_date: Time.current - 1.day)
      expect(subscription.active?).to be true
      expect(subscription.reload.plan).to eq('basic')
      expect(subscription.status).to eq('active')
      expect(subscription.expiry_date).to be_nil
      expect(subscription.session_id).to be_nil
      expect(subscription.session_expires_at).to be_nil
    end

    it 'returns true for an active gold plan not yet expired' do
      subscription = create(:subscription, :gold, status: 'active', expiry_date: Time.current + 1.day)
      expect(subscription.active?).to be true
    end
  end

  describe '#check_and_deactivate_if_expired' do
    it 'does nothing for a basic plan' do
      subscription = create(:subscription, plan: 'basic', status: 'active')
      expect(subscription.check_and_deactivate_if_expired).to be_nil
      expect(subscription.reload.plan).to eq('basic')
    end

    it 'downgrades to basic if expired' do
      subscription = create(:subscription, :gold, status: 'active', expiry_date: Time.current - 1.day)
      subscription.check_and_deactivate_if_expired
      expect(subscription.reload.plan).to eq('basic')
      expect(subscription.status).to eq('active')
      expect(subscription.expiry_date).to be_nil
      expect(subscription.session_id).to be_nil
      expect(subscription.session_expires_at).to be_nil
    end

    it 'does nothing if not expired' do
      subscription = create(:subscription, :gold, status: 'active', expiry_date: Time.current + 1.day)
      subscription.check_and_deactivate_if_expired
      expect(subscription.reload.plan).to eq('gold')
      expect(subscription.status).to eq('active')
    end
  end
end