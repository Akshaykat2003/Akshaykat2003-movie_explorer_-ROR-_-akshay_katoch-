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

    # Use the frontend URL for the success redirect
    success_url = "https://your-frontend-domain.com/subscriptions/success?session_id={CHECKOUT_SESSION_ID}"
    default_url_options = { host: Rails.env.production? ? 'https://movie-explorer-rorakshaykat2003-movie.onrender.com' : 'http://localhost:3000' }
    url_helpers = Rails.application.routes.url_helpers
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
    Rails.logger.info "Completing payment for user ID: #{user.id}, session_id: #{session_id}"

    session = Stripe::Checkout::Session.retrieve(session_id)
    Rails.logger.info "Stripe session retrieved: payment_status=#{session.payment_status}, subscription_id=#{session.subscription}"

    # Check if the subscription ID is present in the session
    unless session.subscription
      Rails.logger.error "No subscription found in Stripe session: #{session_id}"
      return { success: false, error: 'No subscription found in session' }
    end

    subscription = Stripe::Subscription.retrieve(session.subscription)
    return { success: false, error: 'Subscription has no items' } unless subscription.items.data.any?

    # Log all subscriptions with this session_id to debug
    matching_subscriptions = Subscription.where(session_id: session_id)
    Rails.logger.info "All subscriptions with session_id: #{matching_subscriptions.map { |s| { id: s.id, user_id: s.user_id, status: s.status, session_id: s.session_id } }}"

    sub = Subscription.find_by(user: user, session_id: session_id, status: 'pending')
    unless sub
      Rails.logger.error "Pending subscription not found for user ID: #{user.id}, session_id: #{session_id}"
      return { success: false, error: 'Pending subscription not found' }
    end

    Rails.logger.info "Found subscription ID: #{sub.id}, plan: #{sub.plan}, status: #{sub.status}"

    sub.assign_attributes(
      payment_id: subscription.id,
      plan: sub.plan, # Use the plan from the subscription record
      status: subscription.status == 'active' ? 'active' : 'inactive',
      expiry_date: Time.at(subscription.current_period_end),
      session_id: nil,
      session_expires_at: nil
    )

    if sub.save
      Rails.logger.info "Subscription #{sub.id} updated successfully: status=#{sub.status}, expiry_date=#{sub.expiry_date}"
      { success: true, subscription: sub }
    else
      Rails.logger.error "Failed to save subscription: #{sub.errors.full_messages.join(', ')}"
      { success: false, error: sub.errors.full_messages.join(', ') }
    end
  rescue Stripe::StripeError => e
    Rails.logger.error "Stripe error: #{e.message}"
    { success: false, error: e.message }
  rescue StandardError => e
    Rails.logger.error "Unexpected error: #{e.message}"
    { success: false, error: 'An unexpected error occurred' }
  end

  def self.check_subscription_status(subscription)
    return { success: true, subscription: subscription } if subscription.basic?

    stripe_sub = Stripe::Subscription.retrieve(subscription.payment_id)
    return { success: false, error: 'Subscription has no items' } unless stripe_sub.items.data.any?

    new_status = stripe_sub.status == 'active' ? 'active' : 'inactive'
    new_expiry_date = Time.at(stripe_sub.current_period_end)

    subscription.update(
      status: new_status,
      expiry_date: new_expiry_date
    )

    Rails.logger.info "Subscription #{subscription.id} status updated: status=#{new_status}, expiry_date=#{new_expiry_date}"

    { success: true, subscription: subscription }
  rescue Stripe::StripeError => e
    Rails.logger.error "Stripe error: #{e.message}"
    { success: false, error: e.message }
  end

  def self.find_or_create_customer(user)
    customer = nil

    if user.stripe_customer_id
      begin
        customer = Stripe::Customer.retrieve(user.stripe_customer_id)
      rescue Stripe::InvalidRequestError => e
        Rails.logger.error "Invalid Stripe customer ID for user #{user.id}: #{e.message}"
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
      Rails.logger.info "Created new Stripe customer for user #{user.id}: #{customer.id}"
    end

    customer
  rescue Stripe::InvalidRequestError => e
    Rails.logger.error "Failed to create Stripe customer for user #{user.id}: #{e.message}"
    nil
  end
end