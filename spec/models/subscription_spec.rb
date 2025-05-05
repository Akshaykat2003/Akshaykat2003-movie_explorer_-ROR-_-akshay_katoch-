require 'rails_helper'

RSpec.describe Subscription, type: :model do
  let(:user) { create(:user) }
  let(:subscription) { build(:subscription, user: user) }

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'enums' do
    it { should define_enum_for(:plan).with_values(basic: 0, gold: 1, platinum: 2) }
    it { should define_enum_for(:status).with_values(active: 'active', inactive: 'inactive', cancelled: 'cancelled') }
  end

  describe 'validations' do
    it { should validate_presence_of(:plan) }
    it { should validate_presence_of(:status) }

    context 'when plan is not basic' do
      let(:subscription) { build(:subscription, user: user, plan: :gold) }
      it { should validate_presence_of(:payment_id) }
    end

    context 'when plan is basic' do
      let(:subscription) { build(:subscription, user: user, plan: :basic, payment_id: nil) }
      it { should_not validate_presence_of(:payment_id) }
    end
  end

  describe 'callbacks' do
    describe 'before_validation :set_default_status' do
      it 'sets default status to inactive on create' do
        subscription = build(:subscription, user: user, status: nil)
        subscription.valid?
        expect(subscription.status).to eq('inactive')
      end

      it 'does not override an explicitly set status' do
        subscription = build(:subscription, user: user, status: 'active')
        subscription.valid?
        expect(subscription.status).to eq('active')
      end
    end
  end

  describe '.ransackable_associations' do
    it 'returns the correct associations' do
      expect(Subscription.ransackable_associations).to eq(['user'])
    end
  end

  describe '.ransackable_attributes' do
    it 'returns the correct attributes' do
      expect(Subscription.ransackable_attributes).to match_array(%w[id status created_at updated_at user_id plan])
    end
  end

  describe '#plan_duration_in_days' do
    it 'returns 0 for basic plan' do
      subscription.plan = :basic
      expect(subscription.plan_duration_in_days).to eq(0)
    end

    it 'returns 90 for gold plan' do
      subscription.plan = :gold
      expect(subscription.plan_duration_in_days).to eq(90)
    end

    it 'returns 180 for platinum plan' do
      subscription.plan = :platinum
      expect(subscription.plan_duration_in_days).to eq(180)
    end
  end

  describe '#activate!' do
    context 'when plan is basic' do
      let(:subscription) { create(:subscription, user: user, plan: :basic, status: 'inactive') }

      it 'sets status to active and expiry_date to nil' do
        subscription.activate!
        expect(subscription.status).to eq('active')
        expect(subscription.expiry_date).to be_nil
      end
    end

    context 'when plan is not basic' do
      let(:subscription) { create(:subscription, user: user, plan: :gold, status: 'inactive', payment_id: 'pay_123') }

      it 'sets status to active and sets expiry_date based on plan duration' do
        Timecop.freeze(Time.current) do
          subscription.activate!
          expect(subscription.status).to eq('active')
          expect(subscription.expiry_date).to eq(Time.current + 90.days)
        end
      end
    end
  end

  describe '#deactivate!' do
    let(:subscription) { create(:subscription, user: user, plan: :gold, status: 'active', payment_id: 'pay_123') }

    it 'sets status to inactive' do
      subscription.deactivate!
      expect(subscription.status).to eq('inactive')
    end
  end

  describe '#cancel!' do
    let(:subscription) { create(:subscription, user: user, plan: :gold, status: 'active', payment_id: 'pay_123') }

    it 'sets status to cancelled' do
      subscription.cancel!
      expect(subscription.status).to eq('cancelled')
    end
  end

  describe '#upgrade_plan' do
    let(:subscription) { create(:subscription, user: user, plan: :gold, status: 'active', payment_id: 'pay_123') }

    context 'when new plan is valid' do
      it 'updates the plan and sets new expiry_date' do
        Timecop.freeze(Time.current) do
          expect(subscription.upgrade_plan('platinum')).to be_truthy
          expect(subscription.plan).to eq('platinum')
          expect(subscription.expiry_date).to eq(Time.current + 180.days)
        end
      end
    end

    context 'when new plan is invalid' do
      it 'returns false and does not update the plan' do
        expect(subscription.upgrade_plan('invalid')).to be_falsey
        expect(subscription.plan).to eq('gold')
      end
    end
  end

  describe '#downgrade_plan' do
    let(:subscription) { create(:subscription, user: user, plan: :platinum, status: 'active', payment_id: 'pay_123') }

    it 'updates the plan and sets new expiry_date' do
      Timecop.freeze(Time.current) do
        expect(subscription.downgrade_plan('gold')).to be_truthy
        expect(subscription.plan).to eq('gold')
        expect(subscription.expiry_date).to eq(Time.current + 90.days)
      end
    end
  end

  describe '#expired?' do
    context 'when plan is basic' do
      let(:subscription) { create(:subscription, user: user, plan: :basic) }

      it 'returns false' do
        expect(subscription.expired?).to be_falsey
      end
    end

    context 'when plan is not basic' do
      let(:subscription) { create(:subscription, user: user, plan: :gold, payment_id: 'pay_123') }

      context 'when expiry_date is in the future' do
        before { subscription.update(expiry_date: Time.current + 1.day) }

        it 'returns false' do
          expect(subscription.expired?).to be_falsey
        end
      end

      context 'when expiry_date is in the past' do
        before { subscription.update(expiry_date: Time.current - 1.day) }

        it 'returns true' do
          expect(subscription.expired?).to be_truthy
        end
      end

      context 'when expiry_date is nil' do
        before { subscription.update(expiry_date: nil) }

        it 'returns false' do
          expect(subscription.expired?).to be_falsey
        end
      end
    end
  end

  describe '#active?' do
    context 'when plan is basic' do
      let(:subscription) { create(:subscription, user: user, plan: :basic, status: 'active') }

      it 'returns true if status is active' do
        expect(subscription.active?).to be_truthy
      end
    end

    context 'when plan is not basic' do
      let(:subscription) { create(:subscription, user: user, plan: :gold, status: 'active', payment_id: 'pay_123') }

      context 'when subscription is not expired' do
        before { subscription.update(expiry_date: Time.current + 1.day) }

        it 'returns true' do
          expect(subscription.active?).to be_truthy
        end
      end

      context 'when subscription is expired' do
        before { subscription.update(expiry_date: Time.current - 1.day) }

        it 'returns false and deactivates the subscription' do
          expect(subscription.active?).to be_falsey
          expect(subscription.status).to eq('inactive')
        end
      end
    end
  end

  describe '#check_and_deactivate_if_expired' do
    context 'when plan is basic' do
      let(:subscription) { create(:subscription, user: user, plan: :basic, status: 'active') }

      it 'does nothing' do
        subscription.check_and_deactivate_if_expired
        expect(subscription.status).to eq('active')
      end
    end

    context 'when plan is not basic' do
      let(:subscription) { create(:subscription, user: user, plan: :gold, status: 'active', payment_id: 'pay_123') }

      context 'when subscription is expired' do
        before { subscription.update(expiry_date: Time.current - 1.day) }

        it 'deactivates the subscription' do
          subscription.check_and_deactivate_if_expired
          expect(subscription.status).to eq('inactive')
        end
      end

      context 'when subscription is not expired' do
        before { subscription.update(expiry_date: Time.current + 1.day) }

        it 'does not deactivate the subscription' do
          subscription.check_and_deactivate_if_expired
          expect(subscription.status).to eq('active')
        end
      end

      context 'when subscription is already inactive' do
        before { subscription.update(status: 'inactive', expiry_date: Time.current - 1.day) }

        it 'does not change the status' do
          subscription.check_and_deactivate_if_expired
          expect(subscription.status).to eq('inactive')
        end
      end
    end
  end
end