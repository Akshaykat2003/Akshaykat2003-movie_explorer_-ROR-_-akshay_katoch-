class Subscription < ApplicationRecord
  belongs_to :user

  enum plan: { basic: 0, gold: 1, platinum: 2 }
  enum status: { active: 'active', inactive: 'inactive', cancelled: 'cancelled' }

  validates :plan, :status, presence: true
  validates :payment_id, presence: true, unless: -> { basic? }

  before_validation :set_default_status, on: :create

  def self.ransackable_associations(auth_object = nil)
    ["user"]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[id status created_at updated_at user_id plan]  # Add user_id and plan here
  end

  # Plan duration in days based on the plan type
  def plan_duration_in_days
    case plan
    when "gold" then 90
    when "platinum" then 180
    else 0
    end
  end

  # Activate subscription with appropriate expiry for non-basic plans
  def activate!
    if basic?
      update(status: 'active', expiry_date: nil)
    else
      update(status: 'active', expiry_date: Time.current + plan_duration_in_days.days)
    end
  end

  # Deactivate subscription
  def deactivate!
    update(status: 'inactive')
  end

  # Cancel subscription
  def cancel!
    update(status: 'cancelled')
  end

  # Upgrade the plan
  def upgrade_plan(new_plan)
    return false if Subscription.plans[new_plan].nil?

    new_expiry_date = Time.current + Subscription.new(plan: new_plan).plan_duration_in_days.days
    update(plan: new_plan, expiry_date: new_expiry_date)
  end

  # Downgrade the plan
  def downgrade_plan(new_plan)
    upgrade_plan(new_plan)
  end

  # Check if the subscription is expired
  def expired?
    return false if basic?
    expiry_date.present? && expiry_date <= Time.current
  end

  # Check if the subscription is active, and deactivate if expired
  def active?
    check_and_deactivate_if_expired
    status == 'active'
  end

  # Check and deactivate if expired
  def check_and_deactivate_if_expired
    return if basic?
    deactivate! if expired? && status != 'inactive'
  end

  private

  # Set the default status to 'inactive' if not set
  def set_default_status
    self.status ||= 'inactive'
  end
end
