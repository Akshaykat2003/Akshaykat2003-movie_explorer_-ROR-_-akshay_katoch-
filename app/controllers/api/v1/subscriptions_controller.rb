class Api::V1::SubscriptionsController < ApplicationController
  before_action :authenticate_request, except: [:success, :cancel] # Skip authentication for success and cancel
  skip_before_action :verify_authenticity_token, only: [:create, :success, :cancel]

  def create
    logger.info "Creating subscription for user ID: #{@current_user.id}, plan: #{subscription_params[:plan]}"
    
    @result = SubscriptionPaymentService.process_payment(user: @current_user, plan: subscription_params[:plan])

    if @result[:success]
      logger.info "Subscription created successfully with session_id: #{@result[:session_id]}"
      render json: { session_id: @result[:session_id], subscription_id: @result[:subscription_id] }, status: :created
    else
      logger.error "Failed to create subscription: #{@result[:error]}"
      render json: { error: @result[:error] }, status: :unprocessable_entity
    end
  end

  def success
    session_id = params[:session_id]
    logger.info "Processing success callback with session_id: #{session_id}"

    # Retrieve the Stripe session to get the user_id from metadata
    session = Stripe::Checkout::Session.retrieve(session_id)
    user_id = session.metadata&.dig('user_id')

    if user_id.nil?
      logger.error "No user_id found in Stripe session metadata for session_id: #{session_id}"
      render json: { error: "User not found in session metadata" }, status: :unprocessable_entity
      return
    end

    user = User.find_by(id: user_id)
    if user.nil?
      logger.error "User not found for user_id: #{user_id}"
      render json: { error: "User not found" }, status: :unprocessable_entity
      return
    end

    logger.info "Retrieved user_id: #{user_id} from session metadata"
    @result = SubscriptionPaymentService.complete_payment(user: user, session_id: session_id)

    if @result[:success]
      logger.info "Subscription completed successfully: #{@result[:subscription].id}"
      render json: { message: 'Subscription created successfully', subscription: @result[:subscription] }, status: :ok
    else
      logger.error "Failed to complete subscription: #{@result[:error]}"
      render json: { error: @result[:error] }, status: :unprocessable_entity
    end
  end

  def cancel
    render json: { message: 'Subscription creation cancelled' }, status: :ok
  end

  def check_subscription_status
    subscription = @current_user.subscriptions.find(params[:id])
    @result = SubscriptionPaymentService.check_subscription_status(subscription)

    if @result[:success]
      render json: @result[:subscription], status: :ok
    else
      logger.error "Failed to check subscription status: #{@result[:error]}"
      render json: { error: @result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def subscription_params
    params.permit(:plan)
  end
end