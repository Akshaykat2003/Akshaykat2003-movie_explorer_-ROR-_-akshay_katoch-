class SubscriptionPaymentService
  def self.process_payment(user:, plan:)
    return { success: false, error: 'Invalid plan' } unless Subscription.plans.key?(plan)

    customer = find_or_create_customer(user)
    return { success: false, error: 'Failed to create Stripe customer' } unless customer

    price_id = case plan
               when 'basic' then Rails.application.credentials.stripe[:price_basic_monthly]
               when 'gold' then Rails.application.credentials.stripe[:price_gold_monthly]
               when 'platinum' then Rails.application.credentials.stripe[:price_platinum_monthly]
               end

    unless price_id
      Rails.logger.error "Missing price_id for plan: #{plan}"
      return { success: false, error: "Missing price configuration for plan: #{plan}" }
    end

    Rails.logger.info "Using price_id: #{price_id} for plan: #{plan}"

    default_url_options = { host: Rails.env.production? ? 'https://movie-explorer-rorakshaykat2003-movie.onrender.com' : 'http://localhost:3000' }
    url_helpers = Rails.application.routes.url_helpers
    success_url = "#{url_helpers.api_v1_subscriptions_success_url(default_url_options)}?session_id={CHECKOUT_SESSION_ID}"
    cancel_url = url_helpers.api_v1_subscriptions_cancel_url(default_url_options)

    Rails.logger.info "Creating Stripe Checkout session with success_url: #{success_url}, cancel_url: #{cancel_url}"

    session = Stripe::Checkout::Session.create(
      customer: customer.id,
      payment_method_types: ['card'],
      line_items: [{
        price: price_id,
        quantity: 1
      }],
      mode: 'subscription',
      success_url: success_url,
      cancel_url: cancel_url,
      metadata: {
        user_id: user.id.to_s,
        plan: plan
      }
    )

    Rails.logger.info "Created Stripe Checkout session: #{session.id}, url: #{session.url}"

    subscription = Subscription.create!(
      user: user,
      plan: plan,
      status: 'pending',
      session_id: session.id,
      session_expires_at: Time.at(session.expires_at)
    )

    { success: true, session_id: session.id, subscription_id: subscription.id }
  rescue Stripe::StripeError => e
    Rails.logger.error "Stripe error: #{e.message}"
    { success: false, error: e.message }
  rescue StandardError => e
    Rails.logger.error "Unexpected error: #{e.message}"
    { success: false, error: 'An unexpected error occurred' }
  end

  def self.get_valid_session(user:, session_id:)
    subscription = Subscription.find_by(user: user, session_id: session_id, status: 'pending')
    return { success: false, error: 'Session not found or already completed' } unless subscription

    if subscription.session_expires_at < Time.current
      Rails.logger.info "Session #{session_id} expired at #{subscription.session_expires_at}, generating new session"

      result = process_payment(user: user, plan: subscription.plan)
      return result if result[:success]

      return { success: false, error: "Failed to generate new session: #{result[:error]}" }
    end

    { success: true, session_id: session_id, subscription_id: subscription.id }
  rescue Stripe::StripeError => e
    Rails.logger.error "Stripe error: #{e.message}"
    { success: false, error: e.message }
  rescue StandardError => e
    Rails.logger.error "Unexpected error: #{e.message}"
    { success: false, error: 'An unexpected error occurred' }
  end

  def self.complete_payment(user:, session_id:)
    session = Stripe::Checkout::Session.retrieve(session_id)
    subscription = Stripe::Subscription.retrieve(session.subscription)

    return { success: false, error: 'Subscription has no items' } unless subscription.items.data.any?

    sub = Subscription.find_by(user: user, session_id: session_id, status: 'pending')
    return { success: false, error: 'Pending subscription not found' } unless sub

    sub.assign_attributes(
      payment_id: subscription.id,
      plan: sub.plan, # Use the plan from the subscription record
      status: subscription.status == 'active' ? 'active' : 'inactive',
      expiry_date: Time.at(subscription.items.data[0].current_period_end),
      session_id: nil,
      session_expires_at: nil
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