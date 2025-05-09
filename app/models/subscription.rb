class Subscription < ApplicationRecord
  belongs_to :user

  enum plan: { basic: 0, gold: 1, platinum: 2 }
  enum status: { pending: 'pending', active: 'active', inactive: 'inactive', cancelled: 'cancelled' }

  validates :plan, :status, presence: true
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

  def process_payment(plan)
    return { success: false, error: 'Invalid plan' } unless self.class.plans.key?(plan)

    if plan == 'basic'
      update(plan: plan, status: 'active', expiry_date: nil, session_id: nil, session_expires_at: nil)
      return { success: true, subscription: self }
    end

    customer = find_or_create_stripe_customer
    return { success: false, error: 'Failed to create Stripe customer' } unless customer

    price_id = case plan
               when 'gold' then Rails.application.credentials.stripe[:price_gold]
               when 'platinum' then Rails.application.credentials.stripe[:price_platinum]
               else return { success: false, error: "Unknown plan: #{plan}" }
               end

    expiry_date = case plan
                  when 'gold' then Time.current + 1.minute
                  when 'platinum' then Time.current + 1.month
                  end

    base_url = Rails.env.development? ? "http://localhost:5173" : "https://movieexplorerplus.netlify.app"
    success_url = "#{base_url}/subscription-success?session_id={CHECKOUT_SESSION_ID}&plan=#{plan}"
    cancel_url = "#{base_url}/subscription-cancel?session_id={CHECKOUT_SESSION_ID}"

    session = Stripe::Checkout::Session.create(
      customer: customer.id,
      payment_method_types: ['card'],
      line_items: [{ price: price_id, quantity: 1 }],
      mode: 'payment',
      success_url: success_url,
      cancel_url: cancel_url
    )

    update(
      plan: plan,
      status: 'pending',
      session_id: session.id,
      session_expires_at: Time.at(session.expires_at),
      expiry_date: expiry_date
    )

    { success: true, session: session, subscription: self }
  rescue Stripe::StripeError => e
    { success: false, error: "Stripe session creation failed: #{e.message}" }
  rescue StandardError
    { success: false, error: 'An unexpected error occurred' }
  end

  def complete_payment(session_id)
    session = Stripe::Checkout::Session.retrieve(session_id)
    return { success: false, error: 'Payment not completed' } unless session.payment_status == 'paid'
    return { success: false, error: 'Pending subscription not found' } unless status == 'pending' && self.session_id == session_id

    update(status: 'active')
    { success: true, subscription: self }
  rescue Stripe::StripeError => e
    { success: false, error: e.message }
  rescue StandardError
    { success: false, error: 'An unexpected error occurred' }
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
      # Downgrade to basic plan and set to active
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

  def find_or_create_stripe_customer
    if user.stripe_customer_id
      begin
        return Stripe::Customer.retrieve(user.stripe_customer_id)
      rescue Stripe::InvalidRequestError
        user.update(stripe_customer_id: nil)
      end
    end

    customer = Stripe::Customer.create(email: user.email)
    user.update(stripe_customer_id: customer.id)
    customer
  rescue Stripe::InvalidRequestError
    nil
  end
end