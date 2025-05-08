class Api::V1::SubscriptionsController < ApplicationController
  before_action :authenticate_request, only: [:index, :create]
  skip_before_action :verify_authenticity_token, only: [:create, :success, :cancel]

  def index
    subscriptions = @current_user.subscriptions
    render json: { subscriptions: subscriptions.as_json }, status: :ok
  end

  def create
    plan = subscription_params[:plan]

    unless @current_user
      logger.error "Authenticated user not found"
      render json: { error: "Authenticated user not found" }, status: :unauthorized
      return
    end

    mapped_plan = case plan.downcase
                  when 'basic' then 'basic'
                  when 'gold' then 'gold'
                  when 'platinum' then 'platinum'
                  else
                    logger.error "Invalid plan: #{plan}"
                    render json: { error: "Invalid plan: #{plan}" }, status: :unprocessable_entity
                    return
                  end

    logger.info "Creating subscription for user ID: #{@current_user.id}, plan: #{mapped_plan}"

    @result = SubscriptionPaymentService.process_payment(user: @current_user, plan: mapped_plan)

    if @result[:success]
      logger.info "Subscription created successfully with session_id: #{@result[:session].id}, url: #{@result[:session].url}"
      render json: { checkout_url: @result[:session].url, session_id: @result[:session].id, subscription_id: @result[:subscription].id }, status: :created
    else
      logger.error "Failed to create subscription: #{@result[:error]}"
      render json: { error: @result[:error] }, status: :unprocessable_entity
    end
  end

  def success
    session_id = params[:session_id]
    logger.info "Processing success callback with session_id: #{session_id}"

    if session_id.blank?
      logger.error "Session ID is required for success callback"
      render html: "<h1>Error: Session ID is required</h1>".html_safe, status: :unprocessable_entity
      return
    end

    if session_id == '{CHECKOUT_SESSION_ID}'
      logger.error "Invalid session_id provided: #{session_id} in success callback - likely accessed directly"
      render html: "<h1>Error: Invalid Session ID</h1><p>It looks like you accessed this URL directly. Please complete the payment process through the Stripe checkout page to be redirected here with a valid session ID.</p>".html_safe, status: :unprocessable_entity
      return
    end

    if invalid_session_id?(session_id)
      logger.error "Invalid session_id provided: #{session_id} in success callback"
      render html: "<h1>Error: Invalid session ID</h1>".html_safe, status: :unprocessable_entity
      return
    end

    subscription = Subscription.find_by(session_id: session_id, status: 'pending')
    unless subscription
      logger.error "Pending subscription not found for session_id: #{session_id}"
      render html: "<h1>Error: Subscription not found or already processed</h1>".html_safe, status: :not_found
      return
    end

    user = subscription.user
    unless user
      logger.error "User not found for subscription_id: #{subscription.id}"
      render html: "<h1>Error: User not found</h1>".html_safe, status: :not_found
      return
    end

    @result = SubscriptionPaymentService.complete_payment(user: user, session_id: session_id)

    if @result[:success]
      logger.info "Subscription completed successfully: #{@result[:subscription].id}"
      render html: "<h1>Subscription Created Successfully!</h1><p>Your subscription (ID: #{@result[:subscription].id}) for the #{mapped_plan_name(@result[:subscription].plan)} plan is now active.</p>".html_safe, status: :ok
    else
      logger.error "Failed to complete subscription: #{@result[:error]}"
      render html: "<h1>Error: #{@result[:error]}</h1>".html_safe, status: :unprocessable_entity
    end
  end

  def cancel
    session_id = params[:session_id]
    logger.info "Processing cancel callback with session_id: #{session_id}"

    if session_id.blank?
      logger.error "Session ID is required for cancel callback"
      render html: "<h1>Error: Session ID is required</h1>".html_safe, status: :unprocessable_entity
      return
    end

    if session_id == '{CHECKOUT_SESSION_ID}'
      logger.error "Invalid session_id provided: #{session_id} in cancel callback - likely accessed directly"
      render html: "<h1>Error: Invalid Session ID</h1><p>It looks like you accessed this URL directly. Please cancel the payment through the Stripe checkout page to be redirected here with a valid session ID.</p>".html_safe, status: :unprocessable_entity
      return
    end

    if invalid_session_id?(session_id)
      logger.error "Invalid session_id provided: #{session_id} in cancel callback"
      render html: "<h1>Error: Invalid session ID</h1>".html_safe, status: :unprocessable_entity
      return
    end

    subscription = Subscription.find_by(session_id: session_id, status: 'pending')
    unless subscription
      logger.error "Pending subscription not found for session_id: #{session_id}"
      render html: "<h1>Error: Subscription not found or already processed</h1>".html_safe, status: :not_found
      return
    end

    subscription.cancel!
    logger.info "Subscription cancelled successfully for session_id: #{session_id}"
    render html: "<h1>Subscription Cancelled</h1><p>Your subscription (ID: #{subscription.id}) has been cancelled.</p>".html_safe, status: :ok
  end

  private

  def subscription_params
    if params[:subscription].present?
      params[:subscription].permit(:plan).tap do |whitelisted|
        whitelisted[:plan] = whitelisted[:plan] if whitelisted[:plan].present? && Subscription.plans.keys.include?(whitelisted[:plan].downcase)
      end
    else
      params.permit(:plan).tap do |whitelisted|
        whitelisted[:plan] = whitelisted[:plan] if whitelisted[:plan].present? && Subscription.plans.keys.include?(whitelisted[:plan].downcase)
      end
    end
  end

  def invalid_session_id?(session_id)
    logger.info "Validating session_id: #{session_id}"
    session_id.blank? || 
    session_id == '{CHECKOUT_SESSION_ID}' || 
    !session_id.start_with?('cs_')
  end

  def mapped_plan_name(plan)
    case plan
    when 'basic' then 'Basic'
    when 'gold' then 'Gold'
    when 'platinum' then 'Platinum'
    else 'Unknown'
    end
  end
end