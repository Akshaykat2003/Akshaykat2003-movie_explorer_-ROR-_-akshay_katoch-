class SubscriptionPaymentService
  def self.process_payment(user:, plan:)
    return { success: false, error: 'Invalid plan' } unless Subscription.plans.key?(plan)

    customer = find_or_create_customer(user)
    return { success: false, error: 'Failed to create Stripe customer' } unless customer

    price_id = case plan
               when 'basic' then Rails.application.credentials.stripe[:price_basic_monthly]
               when 'gold' then Rails.application.credentials.stripe[:price_gold_monthly]
               when 'platinum' then Rails.application.credentials.stripe[:price_platinum_monthly]
               else
                 Rails.logger.error "Unknown plan: #{plan}"
                 return { success: false, error: "Unknown plan: #{plan}" }
               end

    Rails.logger.info "Using price_id: #{price_id} for plan: #{plan}"

    # Dynamically set default_url_options based on the environment
    default_url_options = if Rails.env.development?
                            { host: 'localhost', protocol: 'http', port: 3000 }
                          else
                            { host: 'movie-explorer-rorakshaykat2003-movie.onrender.com', protocol: 'https', port: nil }
                          end
    url_helpers = Rails.application.routes.url_helpers

    success_url = url_helpers.api_v1_subscriptions_success_url(session_id: '{CHECKOUT_SESSION_ID}', **default_url_options)
    cancel_url = url_helpers.api_v1_subscriptions_cancel_url(session_id: '{CHECKOUT_SESSION_ID}', **default_url_options)

    Rails.logger.info "Creating Stripe Checkout session with success_url: #{success_url}, cancel_url: #{cancel_url}"

    begin
      session = Stripe::Checkout::Session.create(
        customer: customer.id,
        payment_method_types: ['card'],
        line_items: [{
          price: price_id,
          quantity: 1
        }],
        mode: 'subscription',
        success_url: success_url,
        cancel_url: cancel_url
      )

      Rails.logger.info "Created Stripe Checkout session: #{session.id}, url: #{session.url}, expires_at: #{session.expires_at}"
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe session creation failed: #{e.message}"
      return { success: false, error: "Stripe session creation failed: #{e.message}" }
    end

    subscription = Subscription.create!(
      user: user,
      plan: plan,
      status: 'pending',
      session_id: session.id,
      session_expires_at: Time.at(session.expires_at)
    )

    { success: true, session: session, subscription: subscription }
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

    unless session.payment_status == 'paid'
      Rails.logger.error "Payment not completed for session_id: #{session_id}, payment_status: #{session.payment_status}"
      return { success: false, error: 'Payment not completed' }
    end

    unless session.subscription
      Rails.logger.error "No subscription found in Stripe session: #{session_id}"
      return { success: false, error: 'No subscription found in session' }
    end

    stripe_subscription = Stripe::Subscription.retrieve(session.subscription)
    return { success: false, error: 'Subscription has no items' } unless stripe_subscription.items.data.any?

    sub = Subscription.find_by(user: user, session_id: session_id, status: 'pending')
    unless sub
      Rails.logger.error "Pending subscription not found for user ID: #{user.id}, session_id: #{session_id}"
      return { success: false, error: 'Pending subscription not found' }
    end

    Rails.logger.info "Found subscription ID: #{sub.id}, plan: #{sub.plan}, status: #{sub.status}"

    # Access current_period_end from the first item in the subscription
    current_period_end = stripe_subscription.items.data.first.current_period_end
    unless current_period_end
      Rails.logger.error "No current_period_end found in subscription items for session_id: #{session_id}"
      return { success: false, error: 'No current_period_end found in subscription items' }
    end

    sub.assign_attributes(
      status: stripe_subscription.status == 'active' ? 'active' : 'inactive',
      expiry_date: Time.at(current_period_end),
      session_id: session.id,
      session_expires_at: Time.at(session.expires_at)
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
        email: user.email
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