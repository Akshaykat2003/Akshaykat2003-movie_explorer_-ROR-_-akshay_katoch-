class Api::V1::SubscriptionsController < ApplicationController
  before_action :authenticate_request, only: [:index, :create]
  skip_before_action :verify_authenticity_token, only: [:create, :success, :cancel]

  def index
    subscription = @current_user.subscription
    if subscription
      render json: { subscriptions: subscription.as_json }, status: :ok
    else
      render json: { subscriptions: nil }, status: :ok
    end
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
      if mapped_plan == 'basic'
        logger.info "Free basic subscription created successfully: ID #{@result[:subscription].id}"
        render json: { message: "Free basic subscription created", subscription_id: @result[:subscription].id }, status: :created
      else
        logger.info "Subscription created successfully with session_id: #{@result[:session].id}, url: #{@result[:session].url}"
        render json: { checkout_url: @result[:session].url, session_id: @result[:session].id, subscription_id: @result[:subscription].id }, status: :created
      end
    else
      logger.error "Failed to create subscription: #{@result[:error]}"
      render json: { error: @result[:error] }, status: :unprocessable_entity
    end
  end

  def success
    session_id = params[:session_id]
    logger.info "Processing success callback with session_id: #{session_id}, request URL: #{request.url}"

    if session_id.blank?
      logger.error "Session ID is required for success callback"
      render json: { error: "Session ID is required" }, status: :unprocessable_entity
      return
    end

    if session_id == '{CHECKOUT_SESSION_ID}'
      logger.error "Invalid session_id provided: #{session_id} in success callback - likely accessed directly"
      redirect_host = Rails.env.development? ? "http://localhost:5173" : "https://movieexplorerplus.netlify.app"
      render json: {
        error: "Invalid session_id provided: likely accessed directly",
        message: "This endpoint should be accessed via Stripe redirect after payment.",
        instructions: "Call POST /api/v1/subscriptions to get a checkout_url, then redirect to that URL to complete payment.",
        redirect_url: redirect_host
      }, status: :bad_request
      return
    end

    if invalid_session_id?(session_id)
      logger.error "Invalid session_id provided: #{session_id} in success callback"
      render json: { error: "Invalid session ID" }, status: :unprocessable_entity
      return
    end

    # Retrieve the Stripe session using the session_id from the URL parameters
    begin
      stripe_session = Stripe::Checkout::Session.retrieve(session_id)
      logger.info "Successfully retrieved Stripe session: #{session_id}, payment_status: #{stripe_session.payment_status}"
    rescue Stripe::InvalidRequestError => e
      logger.error "Failed to retrieve Stripe session with session_id: #{session_id}. Error: #{e.message}"
      render json: { error: "Invalid or inaccessible session ID", details: e.message }, status: :unprocessable_entity
      return
    end

    subscription = Subscription.find_by(session_id: session_id, status: 'pending')
    unless subscription
      logger.error "Pending subscription not found for session_id: #{session_id}"
      render json: { error: "Subscription not found or already processed" }, status: :not_found
      return
    end

    user = subscription.user
    unless user
      logger.error "User not found for subscription_id: #{subscription.id}"
      render json: { error: "User not found" }, status: :not_found
      return
    end

    @result = SubscriptionPaymentService.complete_payment(user: user, session_id: session_id)

    if @result[:success]
      logger.info "Subscription completed successfully: #{@result[:subscription].id}, new status: #{@result[:subscription].status}"
      redirect_host = Rails.env.development? ? "http://localhost:5173" : "https://movieexplorerplus.netlify.app"
      render json: {
        message: "Subscription completed successfully",
        subscription_id: @result[:subscription].id,
        plan: @result[:subscription].plan,
        redirect_url: "#{redirect_host}/subscription-success?session_id=#{session_id}&plan=#{@result[:subscription].plan}"
      }, status: :ok
    else
      logger.error "Failed to complete subscription: #{@result[:error]}"
      render json: { error: "Failed to complete subscription", details: @result[:error] }, status: :unprocessable_entity
    end
  end

  def cancel
    session_id = params[:session_id]
    logger.info "Processing cancel callback with session_id: #{session_id}, request URL: #{request.url}"

    if session_id.blank?
      logger.error "Session ID is required for cancel callback"
      render json: { error: "Session ID is required" }, status: :unprocessable_entity
      return
    end

    if session_id == '{CHECKOUT_SESSION_ID}'
      logger.error "Invalid session_id provided: #{session_id} in cancel callback - likely accessed directly"
      redirect_host = Rails.env.development? ? "http://localhost:5173" : "https://movieexplorerplus.netlify.app"
      render json: {
        error: "Invalid session_id provided: likely accessed directly",
        message: "This endpoint should be accessed via Stripe redirect after cancellation.",
        redirect_url: redirect_host
      }, status: :bad_request
      return
    end

    if invalid_session_id?(session_id)
      logger.error "Invalid session_id provided: #{session_id} in cancel callback"
      render json: { error: "Invalid session ID" }, status: :unprocessable_entity
      return
    end

    subscription = Subscription.find_by(session_id: session_id, status: 'pending')
    unless subscription
      logger.error "Pending subscription not found for session_id: #{session_id}"
      render json: { error: "Subscription not found or already processed" }, status: :not_found
      return
    end

    subscription.cancel!
    logger.info "Subscription cancelled successfully for session_id: #{session_id}"
    redirect_host = Rails.env.development? ? "http://localhost:5173" : "https://movieexplorerplus.netlify.app"
    render json: {
      message: "Subscription cancelled successfully",
      redirect_url: "#{redirect_host}/subscription-cancel?session_id=#{session_id}"
    }, status: :ok
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