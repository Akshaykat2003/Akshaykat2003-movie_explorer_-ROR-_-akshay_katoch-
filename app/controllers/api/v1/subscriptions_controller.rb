class Api::V1::SubscriptionsController < ApplicationController
  before_action :authenticate_request
  skip_before_action :verify_authenticity_token, only: [:create, :success, :cancel]

  def create
    @result = SubscriptionPaymentService.process_payment(user: @current_user, plan: subscription_params[:plan])

    if @result[:success]
      render json: { session_id: @result[:session_id]}, status: :created
    else
      render json: { error: @result[:error] }, status: :unprocessable_entity
    end
  end

  def success
    session_id = params[:session_id]
    @result = SubscriptionPaymentService.complete_payment(user: @current_user, session_id: session_id)

    if @result[:success]
      render json: { message: 'Subscription created successfully', subscription: @result[:subscription] }, status: :ok
    else
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
      render json: { error: @result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def subscription_params
    params.permit(:plan)
  end
end