class SubscriptionPaymentService
  include Rails.application.routes.url_helpers

  def self.process_payment(user:, plan:)
    return { success: false, error: 'Invalid plan' } unless Subscription.plans.key?(plan)

    customer = find_or_create_customer(user)
    return { success: false, error: 'Failed to create Stripe customer' } unless customer

    price_id = case plan
               when 'basic' then Rails.application.credentials.stripe[:price_basic_monthly] || 'price_basic_monthly'
               when 'gold' then Rails.application.credentials.stripe[:price_gold_monthly] || 'price_gold_monthly'
               when 'platinum' then Rails.application.credentials.stripe[:price_platinum_monthly] || 'price_platinum_monthly'
               end

    session = Stripe::Checkout::Session.create(
      customer: customer.id,
      payment_method_types: ['card'],
      line_items: [{
        price: price_id,
        quantity: 1
      }],
      mode: 'subscription',
      success_url: "#{api_v1_subscriptions_success_url}?session_id={CHECKOUT_SESSION_ID}&user_id=#{user.id}&plan=#{plan}",
      cancel_url: api_v1_subscriptions_cancel_url
    )

    { success: true, checkout_url: session.url }
  rescue Stripe::StripeError => e
    { success: false, error: e.message }
  rescue StandardError => e
    { success: false, error: 'An unexpected error occurred' }
  end

  def self.complete_payment(user:, session_id:, plan:)
    session = Stripe::Checkout::Session.retrieve(session_id)
    subscription = Stripe::Subscription.retrieve(session.subscription)

    return { success: false, error: 'Subscription has no items' } unless subscription.items.data.any?

    sub = Subscription.find_or_initialize_by(user_id: user.id, payment_id: subscription.id)
    sub.assign_attributes(
      plan: plan,
      status: subscription.status == 'active' ? 'active' : 'inactive',
      expiry_date: Time.at(subscription.items.data[0].current_period_end)
    )

    if sub.save
      { success: true, subscription: sub }
    else
      { success: false, error: sub.errors.full_messages.join(', ') }
    end
  rescue Stripe::StripeError => e
    { success: false, error: e.message }
  end

  def self.check_subscription_status(subscription)
    return { success: true, subscription: subscription } if subscription.basic?

    stripe_sub = Stripe::Subscription.retrieve(subscription.payment_id)
    return { success: false, error: 'Subscription has no items' } unless stripe_sub.items.data.any?

    new_status = stripe_sub.status == 'active' ? 'active' : 'inactive'
    new_expiry_date = Time.at(stripe_sub.items.data[0].current_period_end)

    subscription.update(
      status: new_status,
      expiry_date: new_expiry_date
    )

    { success: true, subscription: subscription }
  rescue Stripe::StripeError => e
    { success: false, error: e.message }
  end

  def self.find_or_create_customer(user)
    customer = nil

    if user.stripe_customer_id
      begin
        customer = Stripe::Customer.retrieve(user.stripe_customer_id)
      rescue Stripe::InvalidRequestError => e
        customer = nil
        user.update(stripe_customer_id: nil)
      end
    end

    unless customer
      customer = Stripe::Customer.create(
        email: user.email,
        metadata: { user_id: user.id }
      )
      user.update(stripe_customer_id: customer.id)
    end

    customer
  rescue Stripe::InvalidRequestError => e
    nil
  end
end