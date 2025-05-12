class SubscriptionPaymentService
  def self.process_payment(user:, plan:, is_mobile: false)
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

    price = Stripe::Price.retrieve(price_id)
    amount = price.unit_amount 
    currency = price.currency 

    expiry_date = case plan
                  when 'gold' then Time.current + 1.month
                  when 'platinum' then Time.current + 1.month
                  end

    if is_mobile
   
      payment_intent = Stripe::PaymentIntent.create(
        customer: customer.id,
        amount: amount,
        currency: currency,
        payment_method_types: ['card'],
        metadata: { subscription_id: subscription.id, plan: plan }
      )

      subscription.update!(
        plan: plan,
        status: 'pending',
        session_id: payment_intent.id,
        session_expires_at: nil, 
        expiry_date: expiry_date
      )

      amount_in_rupees = amount / 100 

      { success: true, payment_intent: payment_intent, subscription: subscription, amount: amount_in_rupees, currency: currency }
    else
      
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
    end
  rescue Stripe::StripeError => e
    { success: false, error: "Stripe payment creation failed: #{e.message}" }
  rescue StandardError => e
    { success: false, error: "An unexpected error occurred: #{e.message}" }
  end

  def self.complete_payment(user:, session_id: nil, payment_intent_id: nil)
    if payment_intent_id
  
      payment_intent = Stripe::PaymentIntent.retrieve(payment_intent_id)
      return { success: false, error: 'Payment not completed' } unless payment_intent.status == 'succeeded'

      sub = Subscription.find_by(user: user, session_id: payment_intent_id, status: 'pending')
      return { success: false, error: 'Pending subscription not found' } unless sub

      sub.update!(status: 'active')
      { success: true, subscription: sub }
    else
      
      session = Stripe::Checkout::Session.retrieve(session_id)
      return { success: false, error: 'Payment not completed' } unless session.payment_status == 'paid'

      sub = Subscription.find_by(user: user, session_id: session_id, status: 'pending')
      return { success: false, error: 'Pending subscription not found' } unless sub

      sub.update!(status: 'active')
      { success: true, subscription: sub }
    end
  rescue Stripe::StripeError => e
    { success: false, error: e.message }
  rescue StandardError => e
    { success: false, error: "An unexpected error occurred: #{e.message}" }
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