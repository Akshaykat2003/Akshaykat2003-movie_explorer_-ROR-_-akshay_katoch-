class SubscriptionPaymentService
  def self.process_payment(user:, plan:)
    return { success: false, error: 'Invalid plan' } unless Subscription.plans.key?(plan)

    subscription = user.subscription || Subscription.new(user: user)

    if plan == 'basic'
      subscription.update!(plan: plan, status: 'active', expiry_date: nil, session_id: nil, session_expires_at: nil)
      return { success: true, subscription: subscription }
    end

    customer = find_or_create_customer(user)
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

    subscription.update!(
      plan: plan,
      status: 'pending',
      session_id: session.id,
      session_expires_at: Time.at(session.expires_at),
      expiry_date: expiry_date
    )

    { success: true, session: session, subscription: subscription }
  rescue Stripe::StripeError => e
    { success: false, error: "Stripe session creation failed: #{e.message}" }
  rescue StandardError
    { success: false, error: 'An unexpected error occurred' }
  end

  def self.complete_payment(user:, session_id:)
    session = Stripe::Checkout::Session.retrieve(session_id)
    return { success: false, error: 'Payment not completed' } unless session.payment_status == 'paid'

    sub = Subscription.find_by(user: user, session_id: session_id, status: 'pending')
    return { success: false, error: 'Pending subscription not found' } unless sub

    sub.update!(status: 'active')
    { success: true, subscription: sub }
  rescue Stripe::StripeError => e
    { success: false, error: e.message }
  rescue StandardError
    { success: false, error: 'An unexpected error occurred' }
  end

  def self.find_or_create_customer(user)
    customer = if user.stripe_customer_id
                 Stripe::Customer.retrieve(user.stripe_customer_id)
               else
                 Stripe::Customer.create(email: user.email).tap do |c|
                   user.update!(stripe_customer_id: c.id)
                 end
               end
    customer
  rescue Stripe::InvalidRequestError
    user.update!(stripe_customer_id: nil) if user.stripe_customer_id
    nil
  end
end