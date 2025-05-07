class Subscription < ApplicationRecord
  belongs_to :user

  enum plan: { basic: 0, gold: 1, platinum: 2 }
  enum status: { pending: 'pending', active: 'active', inactive: 'inactive', cancelled: 'cancelled' }

  validates :plan, :status, presence: true
  validates :payment_id, presence: true, unless: -> { basic? || pending? }

  before_validation :set_default_status, on: :create

  def self.ransackable_associations(auth_object = nil)
    ["user"]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[id status created_at updated_at user_id plan]
  end

  def plan_duration_in_days
    case plan
    when "gold" then 90
    when "platinum" then 180
    else 0
    end
  end

  def activate!
    if basic?
      update(status: 'active', expiry_date: nil)
    else
      update(status: 'active', expiry_date: Time.current + plan_duration_in_days.days)
    end
  end

  def deactivate!
    update(status: 'inactive')
  end

  def cancel!
    update(status: 'cancelled')
  end

  def upgrade_plan(new_plan)
    return false if Subscription.plans[new_plan].nil?
    new_expiry_date = Time.current + Subscription.new(plan: new_plan).plan_duration_in_days.days
    update(plan: new_plan, expiry_date: new_expiry_date)
  end

  def downgrade_plan(new_plan)
    upgrade_plan(new_plan)
  end

  def expired?
    return false if basic?
    expiry_date.present? && expiry_date <= Time.current
  end

  def active?
    check_and_deactivate_if_expired
    status == 'active'
  end

  def check_and_deactivate_if_expired
    return if basic?
    deactivate! if expired? && status != 'inactive'
  end

  def pending?
    status == 'pending'
  end

  private

  def set_default_status
    self.status ||= 'inactive'
  end
end