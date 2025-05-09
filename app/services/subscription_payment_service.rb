class SubscriptionPaymentService
  def self.process_payment(user:, plan:)
    return { success: false, error: 'Invalid plan' } unless Subscription.plans.key?(plan)

    # Find the user's existing subscription, if any
    subscription = user.subscription

    # Handle the "basic" plan separately
    if plan == 'basic'
      Rails.logger.info "Processing free basic subscription for user ID: #{user.id}"

      if subscription
        # Update the existing subscription to basic
        subscription.update!(
          plan: plan,
          status: 'active',
          expiry_date: nil, # Basic plans don't have an expiry date
          session_id: nil,
          session_expires_at: nil
        )
        Rails.logger.info "Updated existing subscription to basic for user ID: #{user.id}: Subscription ID #{subscription.id}"
      else
        # Create a new subscription if none exists (e.g., after user deletion)
        subscription = Subscription.create!(
          user: user,
          plan: plan,
          status: 'active',
          created_at: Time.current,
          updated_at: Time.current
        )
        Rails.logger.info "Created free basic subscription: ID #{subscription.id} for user ID: #{user.id}"
      end

      return { success: true, subscription: subscription }
    end

    # Handle paid plan
    customer = find_or_create_customer(user)
    return { success: false, error: 'Failed to create Stripe customer' } unless customer

    price_id = case plan
               when 'gold' then Rails.application.credentials.stripe[:price_gold]
               when 'platinum' then Rails.application.credentials.stripe[:price_platinum]
               else
                 Rails.logger.error "Unknown paid plan: #{plan}"
                 return { success: false, error: "Unknown plan: #{plan}" }
               end

    Rails.logger.info "Using price_id: #{price_id} for plan: #{plan}"

    # Set expiry date based on plan
    expiry_date = case plan
                  when 'gold' then Time.current + 1.day
                  when 'platinum' then Time.current + 1.month
                  end

   
    base_url = Rails.env.development? ? "http://localhost:3000" : "https://movieexplorerplus.netlify.app"
    success_url = "#{base_url}/subscriptions/success?session_id={CHECKOUT_SESSION_ID}"
    cancel_url  = "#{base_url}/api/v1/subscriptions/cancel?session_id={CHECKOUT_SESSION_ID}"

    Rails.logger.info "Creating Stripe Checkout session with success_url: #{success_url}, cancel_url: #{cancel_url}"

    begin
      session = Stripe::Checkout::Session.create(
        customer: customer.id,
        payment_method_types: ['card'],
        line_items: [{
          price: price_id,
          quantity: 1
        }],
        mode: 'payment', # Use one-off payment instead of subscription
        success_url: success_url,
        cancel_url: cancel_url
      )

      Rails.logger.info "Created Stripe Checkout session: #{session.id}, url: #{session.url}, expires_at: #{session.expires_at}"

      if subscription
        # Update the existing subscription
        subscription.update!(
          plan: plan,
          status: 'pending',
          session_id: session.id,
          session_expires_at: Time.at(session.expires_at),
          expiry_date: expiry_date
        )
        Rails.logger.info "Updated existing subscription to pending for user ID: #{user.id}: Subscription ID #{subscription.id}"
      else
        # Create a new subscription if none exists
        subscription = Subscription.create!(
          user: user,
          plan: plan,
          status: 'pending',
          session_id: session.id,
          session_expires_at: Time.at(session.expires_at),
          expiry_date: expiry_date
        )
        Rails.logger.info "Created new pending subscription: ID #{subscription.id} for user ID: #{user.id}"
      end

      { success: true, session: session, subscription: subscription }
    rescue Stripe::StripeError => e
      Rails.logger.error "Stripe session creation failed: #{e.message}"
      { success: false, error: "Stripe session creation failed: #{e.message}" }
    rescue StandardError => e
      Rails.logger.error "Unexpected error: #{e.message}"
      { success: false, error: 'An unexpected error occurred' }
    end
  end

  def self.complete_payment(user:, session_id:)
    Rails.logger.info "Completing payment for user ID: #{user.id}, session_id: #{session_id}"

    session = Stripe::Checkout::Session.retrieve(session_id)
    Rails.logger.info "Stripe session retrieved: payment_status=#{session.payment_status}"

    unless session.payment_status == 'paid'
      Rails.logger.error "Payment not completed for session_id: #{session_id}, payment_status: #{session.payment_status}"
      return { success: false, error: 'Payment not completed' }
    end

    sub = Subscription.find_by(user: user, session_id: session_id, status: 'pending')
    unless sub
      Rails.logger.error "Pending subscription not found for user ID: #{user.id}, session_id: #{session_id}"
      return { success: false, error: 'Pending subscription not found' }
    end

    Rails.logger.info "Before update: #{sub.attributes.inspect}"
    sub.assign_attributes(
      status: 'active'
      # expiry_date is already set during process_payment
    )

    if sub.save
      Rails.logger.info "Subscription #{sub.id} updated successfully: status=#{sub.status}, expiry_date=#{sub.expiry_date}"
      { success: true, subscription: sub }
    else
      Rails.logger.error "Failed to save subscription: #{sub.errors.full_messages.join(', ')}"
      return { success: false, error: sub.errors.full_messages.join(', ') }
    end
  rescue Stripe::StripeError => e
    Rails.logger.error "Stripe error: #{e.message}"
    { success: false, error: e.message }
  rescue StandardError => e
    Rails.logger.error "Unexpected error: #{e.message}"
    { success: false, error: 'An unexpected error occurred' }
  end

  def self.find_or_create_customer(user)
    if user.stripe_customer_id
      begin
        return Stripe::Customer.retrieve(user.stripe_customer_id)
      rescue Stripe::InvalidRequestError => e
        Rails.logger.error "Invalid Stripe customer ID for user #{user.id}: #{e.message}"
        user.update(stripe_customer_id: nil)
      end
    end

    customer = Stripe::Customer.create(email: user.email)
    user.update(stripe_customer_id: customer.id)
    Rails.logger.info "Created new Stripe customer for user #{user.id}: #{customer.id}"
    customer
  rescue Stripe::InvalidRequestError => e
    Rails.logger.error "Failed to create Stripe customer for user #{user.id}: #{e.message}"
    nil
  end
end