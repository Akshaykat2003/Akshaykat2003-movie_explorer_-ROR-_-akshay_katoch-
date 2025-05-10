class Api::V1::SubscriptionsController < ApplicationController
  before_action :authenticate_request, only: [:index, :create]
  skip_before_action :verify_authenticity_token, only: [:create, :success, :cancel]

  def index
    render json: { subscriptions: @current_user.subscription&.as_json || nil }, status: :ok
  end

  def create
    render json: { error: "Authenticated user not found" }, status: :unauthorized unless @current_user

    plan = subscription_params[:plan]&.downcase
    mapped_plan = %w[basic gold platinum].include?(plan) ? plan : (render json: { error: "Invalid plan: #{plan}" }, status: :unprocessable_entity and return)

    result = SubscriptionPaymentService.process_payment(user: @current_user, plan: mapped_plan)

    if result[:success]
      if mapped_plan == 'basic'
        render json: { message: "Free basic subscription created", subscription_id: result[:subscription].id }, status: :created
      else
        render json: { checkout_url: result[:session].url, session_id: result[:session].id, subscription_id: result[:subscription].id }, status: :created
      end
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def success
    session_id = params[:session_id]
    render json: { error: "Session ID is required" }, status: :unprocessable_entity if session_id.blank?
    render json: invalid_session_response("payment"), status: :bad_request if session_id == '{CHECKOUT_SESSION_ID}'
    render json: { error: "Invalid session ID" }, status: :unprocessable_entity if invalid_session_id?(session_id)

    subscription = Subscription.find_by(session_id: session_id, status: 'pending')
    render json: { error: "Subscription not found or already processed" }, status: :not_found unless subscription
    render json: { error: "User not found" }, status: :not_found unless subscription.user

    result = SubscriptionPaymentService.complete_payment(user: subscription.user, session_id: session_id)
    if result[:success]
      redirect_host = Rails.env.development? ? "http://localhost:5173" : "https://movieexplorerplus.netlify.app"
      render json: {
        message: "Subscription completed successfully",
        subscription_id: result[:subscription].id,
        plan: result[:subscription].plan,
        redirect_url: "#{redirect_host}/subscription-success?session_id=#{session_id}&plan=#{result[:subscription].plan}"
      }, status: :ok
    else
      render json: { error: "Failed to complete subscription", details: result[:error] }, status: :unprocessable_entity
    end
  end

  def cancel
    session_id = params[:session_id]
    render json: { error: "Session ID is required" }, status: :unprocessable_entity if session_id.blank?
    render json: invalid_session_response("cancellation"), status: :bad_request if session_id == '{CHECKOUT_SESSION_ID}'
    render json: { error: "Invalid session ID" }, status: :unprocessable_entity if invalid_session_id?(session_id)

    subscription = Subscription.find_by(session_id: session_id, status: 'pending')
    render json: { error: "Subscription not found or already processed" }, status: :not_found unless subscription

    subscription.cancel!
    redirect_host = Rails.env.development? ? "http://localhost:5173" : "https://movieexplorerplus.netlify.app"
    render json: { message: "Subscription cancelled successfully", redirect_url: "#{redirect_host}/subscription-cancel?session_id=#{session_id}" }, status: :ok
  end

  private

  def subscription_params
    (params[:subscription] || params).permit(:plan).tap do |whitelisted|
      whitelisted[:plan] = whitelisted[:plan] if whitelisted[:plan].present? && Subscription.plans.keys.include?(whitelisted[:plan].downcase)
    end
  end

  def invalid_session_id?(session_id)
    session_id.blank? || session_id == '{CHECKOUT_SESSION_ID}' || !session_id.start_with?('cs_')
  end

  def invalid_session_response(type)
    redirect_host = Rails.env.development? ? "http://localhost:5173" : "https://movieexplorerplus.netlify.app"
    {
      error: "Invalid session_id provided: likely accessed directly",
      message: "This endpoint should be accessed via Stripe redirect after #{type}.",
      instructions: type == "payment" ? "Call POST /api/v1/subscriptions to get a checkout_url, then redirect to that URL to complete payment." : nil,
      redirect_url: redirect_host
    }
  end
end