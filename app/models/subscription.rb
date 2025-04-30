class Subscription < ApplicationRecord
  belongs_to :user

  enum plan: { basic: 0, premium: 1, gold: 2 }
  enum status: { active: 'active', inactive: 'inactive', cancelled: 'cancelled' }

  validates :plan, :status, :payment_id, presence: true

  before_validation :set_default_status, on: :create

  # Activate subscription and set expiry (default 30 days)
  def activate!(duration_in_days = 30)
    update(
      status: 'active',
      expiry_date: Time.current + duration_in_days.days
    )
  end

  def deactivate!
    update(status: 'inactive')
  end

  def cancel!
    update(status: 'cancelled')
  end

  def upgrade_plan(new_plan)
    if Subscription.plans.key?(new_plan.to_s)
      update(plan: new_plan)
    else
      errors.add(:plan, "Invalid plan name")
      false
    end
  end

  def downgrade_plan(new_plan)
    upgrade_plan(new_plan)
  end

  def active?
    status == 'active' && !expired?
  end

  def expired?
    expiry_date.present? && expiry_date <= Time.current
  end

  private

  def set_default_status
    self.status ||= 'inactive'
  end
end
