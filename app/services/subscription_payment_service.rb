class SubscriptionPaymentService
  def self.process_payment(user:, plan:, payment_params:)
    return nil if plan.blank?

    if plan != "basic" && payment_params[:payment_id].blank?
      Rails.logger.error "Missing payment_id for paid plan"
      return nil
    end

    if payment_params[:payment_id] == "fail"
      Rails.logger.error "Simulated payment failure"
      return nil
    end

  
    subscription = user.subscription || user.build_subscription

    subscription.plan = plan
    subscription.payment_id = (plan == "basic" ? nil : payment_params[:payment_id])
    subscription.status = "active"


    case plan
    when "gold"
      subscription.expiry_date = Time.current + 90.days
    when "platinum"
      subscription.expiry_date = Time.current + 180.days
    else
      subscription.expiry_date = nil 
    end

    if subscription.save
      Rails.logger.info "Subscription created successfully"
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
