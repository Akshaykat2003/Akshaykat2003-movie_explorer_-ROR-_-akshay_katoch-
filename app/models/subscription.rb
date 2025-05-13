class Subscription < ApplicationRecord
  belongs_to :user


  enum plan: { basic: 0, gold: 1, platinum: 2 }
  enum status: { pending: 'pending', active: 'active', inactive: 'inactive', cancelled: 'cancelled' }

  attr_accessor :raw_plan, :raw_status


  def plan=(value)
    self.raw_plan = value
    if self.class.plans.key?(value.to_s)
      super(value)
    else
     
      write_attribute(:plan, nil)
    end
  end


  def status=(value)
    self.raw_status = value
    if self.class.statuses.key?(value.to_s)
      super(value)
    else

      write_attribute(:status, nil)
    end
  end


  def plan
    raw_plan || super
  end

  def status
    raw_status || super
  end

  validates :plan, :status, presence: true
  validates :plan, inclusion: { in: %w[basic gold platinum], message: 'is not a valid plan' }
  validates :status, inclusion: { in: %w[pending active inactive cancelled], message: 'is not a valid status' }
  validates :session_expires_at, presence: true, if: -> { pending? }
  validates :expiry_date, presence: true, unless: -> { basic? }

  before_validation :set_default_status, on: :create

  def self.ransackable_associations(auth_object = nil)
    ["user"]
  end
  class Subscription < ApplicationRecord
  belongs_to :user

  # Define enums
  enum plan: { basic: 0, gold: 1, platinum: 2 }
  enum status: { pending: 'pending', active: 'active', inactive: 'inactive', cancelled: 'cancelled' }

  attr_accessor :raw_plan, :raw_status

  # Override the plan setter to store the raw value
  def plan=(value)
    self.raw_plan = value
    if self.class.plans.key?(value.to_s)
      super(value)
    else
      # Set the internal enum value to nil to prevent ArgumentError, validation will catch the invalid value
      write_attribute(:plan, nil)
    end
  end

  # Override the status setter to store the raw value
  def status=(value)
    self.raw_status = value
    if self.class.statuses.key?(value.to_s)
      super(value)
    else
      # Set the internal enum value to nil to prevent ArgumentError, validation will catch the invalid value
      write_attribute(:status, nil)
    end
  end

  # Override the getter for validation purposes
  def plan
    raw_plan || super
  end

  def status
    raw_status || super
  end

  validates :plan, :status, presence: true
  validates :plan, inclusion: { in: %w[basic gold platinum], message: 'is not a valid plan' }
  validates :status, inclusion: { in: %w[pending active inactive cancelled], message: 'is not a valid status' }
  validates :session_expires_at, presence: true, if: -> { pending? }
  validates :expiry_date, presence: true, unless: -> { basic? }

  before_validation :set_default_status, on: :create

  def self.ransackable_associations(auth_object = nil)
    ["user"]
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[id status created_at updated_at user_id plan session_id session_expires_at expiry_date]
  end

  def self.create_default_for_user(user)
    create(user: user, plan: 'basic', status: 'active', created_at: Time.current, updated_at: Time.current)
  rescue StandardError
    nil
  end

  def activate!
    update!(status: 'active', expiry_date: basic? ? nil : expiry_date)
  end

  def deactivate!
    update!(status: 'inactive')
  end

  def cancel!
    update!(status: 'cancelled', session_id: nil, session_expires_at: nil)
  end

  def change_plan(new_plan)
    return false unless self.class.plans.key?(new_plan)

    new_expiry_date = case new_plan
                      when 'gold' then Time.current + 1.minute
                      when 'platinum' then Time.current + 1.month
                      else nil
                      end
    update!(plan: new_plan, expiry_date: new_expiry_date)
    true
  end

  def expired?
    !basic? && expiry_date.present? && expiry_date <= Time.current
  end

  def active?
    check_and_deactivate_if_expired
    status == 'active'
  end

  def check_and_deactivate_if_expired
    return if basic?

    if expired? && status != 'inactive'
      update!(plan: 'basic', status: 'active', expiry_date: nil, session_id: nil, session_expires_at: nil)
    end
  end

  def pending?
    status == 'pending'
  end

  private

  def set_default_status
    self.status ||= 'pending'
  end
end

  def self.ransackable_attributes(auth_object = nil)
    %w[id status created_at updated_at user_id plan session_id session_expires_at expiry_date]
  end

  def self.create_default_for_user(user)
    create(user: user, plan: 'basic', status: 'active', created_at: Time.current, updated_at: Time.current)
  rescue StandardError
    nil
  end

  def activate!
    update!(status: 'active', expiry_date: basic? ? nil : expiry_date)
  end

  def deactivate!
    update!(status: 'inactive')
  end

  def cancel!
    update!(status: 'cancelled', session_id: nil, session_expires_at: nil)
  end

  def change_plan(new_plan)
    return false unless self.class.plans.key?(new_plan)

    new_expiry_date = case new_plan
                      when 'gold' then Time.current + 1.minute
                      when 'platinum' then Time.current + 1.month
                      else nil
                      end
    update!(plan: new_plan, expiry_date: new_expiry_date)
    true
  end

  def expired?
    !basic? && expiry_date.present? && expiry_date <= Time.current
  end

  def active?
    check_and_deactivate_if_expired
    status == 'active'
  end

  def check_and_deactivate_if_expired
    return if basic?

    if expired? && status != 'inactive'
      update!(plan: 'basic', status: 'active', expiry_date: nil, session_id: nil, session_expires_at: nil)
    end
  end

  def pending?
    status == 'pending'
  end

  private

  def set_default_status
    self.status ||= 'pending'
  end
end