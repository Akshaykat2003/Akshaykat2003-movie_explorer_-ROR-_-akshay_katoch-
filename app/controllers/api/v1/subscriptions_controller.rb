class Api::V1::SubscriptionsController < ApplicationController
  before_action :authenticate_request, only: [:index, :create, :check_subscription_status, :confirm_payment] 
  skip_before_action :verify_authenticity_token, only: [:create, :success, :cancel, :confirm_payment]
  before_action :validate_session_and_subscription, only: [:success, :cancel]

  def index
    render json: { subscriptions: @current_user.subscription&.as_json || nil }, status: :ok
  end

  def create
    plan = subscription_params[:plan]
    unless Subscription.plans.keys.include?(plan)
      render json: { errors: ["Invalid plan. Must be one of: #{Subscription.plans.keys.join(', ')}"] }, status: :unprocessable_entity
      return
    end

    client_type = request.headers['X-Client-Type'] || 'web'
    is_mobile = client_type == 'mobile'
    result = SubscriptionPaymentService.process_payment(user: @current_user, plan: plan, is_mobile: is_mobile)

    if result[:success]
      subscription = result[:subscription]
      if is_mobile
        render json: {
          message: 'Payment Intent created',
          subscription_id: subscription.id,
          client_secret: result[:payment_intent].client_secret,
          amount: result[:amount], 
          currency: result[:currency] 
        }, status: :created
      else
        render json: {
          checkout_url: result[:session].url,
          session_id: result[:session].id,
          subscription_id: subscription.id
        }, status: :created
      end
    else
      render json: { errors: [result[:error]] }, status: :unprocessable_entity
    end
  end

  def success
    result = SubscriptionPaymentService.complete_payment(user: @subscription.user, session_id: @session_id)
    if result[:success]
      redirect_url = "#{redirect_host}/subscription-success?session_id=#{@session_id}&plan=#{result[:subscription].plan}"
      render json: {
        message: "Subscription completed successfully",
        subscription_id: result[:subscription].id,
        plan: result[:subscription].plan,
        redirect_url: redirect_url
      }, status: :ok
    else
      render json: { errors: ["Failed to complete subscription: #{result[:error]}"] }, status: :unprocessable_entity
    end
  end

  def cancel
    @subscription.cancel!
    redirect_url = "#{redirect_host}/subscription-cancel?session_id=#{@session_id}"
    render json: { message: "Subscription cancelled successfully", redirect_url: redirect_url }, status: :ok
  end

  def confirm_payment
    payment_intent_id = params[:payment_intent_id]
    subscription_id = params[:subscription_id]

    if payment_intent_id.blank? || subscription_id.blank?
      render json: { errors: ["Payment Intent ID and Subscription ID are required"] }, status: :unprocessable_entity
      return
    end

    subscription = Subscription.find_by(id: subscription_id, user: @current_user, status: 'pending')
    unless subscription
      render json: { errors: ["Subscription not found or already processed"] }, status: :not_found
      return
    end

    result = SubscriptionPaymentService.complete_payment(user: @current_user, payment_intent_id: payment_intent_id)
    if result[:success]
      render json: {
        message: "Subscription completed successfully",
        subscription_id: result[:subscription].id,
        plan: result[:subscription].plan
      }, status: :ok
    else
      render json: { errors: ["Failed to complete subscription: #{result[:error]}"] }, status: :unprocessable_entity
    end
  end

  def check_subscription_status
    subscription = @current_user.subscription
    unless subscription
      render json: { errors: ["Subscription not found"] }, status: :not_found
      return
    end

    render json: subscription.as_json, status: :ok
  end

  private

  def subscription_params
    permitted = (params[:subscription] || params).permit(:plan)
    plan = permitted[:plan]&.downcase
    permitted[:plan] = plan if plan && Subscription.plans.keys.include?(plan)
    permitted
  end

  def validate_session_and_subscription
    @session_id = params[:session_id]
    if @session_id.blank?
      render json: { errors: ["Session ID is required"] }, status: :unprocessable_entity
      return
    end
    if @session_id == '{CHECKOUT_SESSION_ID}'
      render json: invalid_session_response(action_name == "success" ? "payment" : "cancellation"), status: :bad_request
      return
    end
    if invalid_session_id?(@session_id)
      render json: { errors: ["Invalid session ID"] }, status: :unprocessable_entity
      return
    end

    @subscription = Subscription.find_by(session_id: @session_id, status: 'pending')
    unless @subscription
      render json: { errors: ["Subscription not found or already processed"] }, status: :not_found
      return
    end
    unless @subscription.user
      render json: { errors: ["User not found"] }, status: :not_found
      return
    end
    true
  end

  def invalid_session_id?(session_id)
    session_id.blank? || session_id == '{CHECKOUT_SESSION_ID}' || !session_id.start_with?('cs_')
  end

  def invalid_session_response(type)
    {
      error: "Invalid session_id provided: likely accessed directly",
      message: "This endpoint should be accessed via Stripe redirect after #{type}.",
      instructions: type == "payment" ? "Call POST /api/v1/subscriptions to get a checkout_url, then redirect to that URL to complete payment." : nil,
      redirect_url: redirect_host
    }
  end

  def redirect_host
    Rails.env.development? ? "http://localhost:5173" : "https://movieexplorerplus.netlify.app"
  end
end