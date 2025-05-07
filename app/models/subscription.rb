class Subscription < ApplicationRecord
  belongs_to :user

  enum plan: { basic: 0, gold: 1, platinum: 2 }
  enum status: { pending: 'pending', active: 'active', inactive: 'inactive', cancelled: 'cancelled' }

  validates :plan, :status, presence: true
  validates :payment_id, presence: true, uniqueness: true, unless: -> { basic? || pending? }
  validates :session_expires_at, presence: true, if: -> { pending? }

  before_validation :set_default_status, on: :create

  def self.ransackable_associations(auth_object = nil)
    ["user"]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[id status created_at updated_at user_id plan]
  end

  def activate!
    if basic?
      update(status: 'active', expiry_date: nil)
    else
      # Expiry date should be set by Stripe's current_period_end, not a fixed duration
      update(status: 'active')
    end
    Rails.logger.info "Subscription #{id} activated with status: active, expiry_date: #{expiry_date}"
  end

  def deactivate!
    update(status: 'inactive')
    Rails.logger.info "Subscription #{id} deactivated with status: inactive"
  end

  def cancel!
    update(status: 'cancelled')
    Rails.logger.info "Subscription #{id} cancelled with status: cancelled"
  end

  def upgrade_plan(new_plan)
    return false if Subscription.plans[new_plan].nil?
    # Expiry date should be updated via Stripe when the plan changes
    update(plan: new_plan)
    Rails.logger.info "Subscription #{id} upgraded to plan: #{new_plan}, expiry_date: #{expiry_date}"
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
    if expired? && status != 'inactive'
      deactivate!
    end
  end

  def pending?
    status == 'pending'
  end

  private

  def set_default_status
    self.status ||= 'pending' # Default to pending for new subscriptions
  end
end