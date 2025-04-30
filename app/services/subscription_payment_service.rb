class SubscriptionPaymentService
  def self.process_payment(user:, plan:, payment_params:)
    payment_id = payment_params[:payment_id]

    return nil if payment_id.blank? || plan.blank?

    # Either find an existing subscription or build a new one
    subscription = user.subscription || user.build_subscription

    subscription.assign_attributes(
      plan: plan,
      status: 'active',
      payment_id: payment_id
    )

    if subscription.save
      return subscription
    else
      Rails.logger.error "Subscription save failed: #{subscription.errors.full_messages.join(', ')}"
      return nil
    end
  rescue => e
    Rails.logger.error "Payment Failed: #{e.class} - #{e.message}"
    nil
  end
end
