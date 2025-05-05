module Api
  module V1
    class SubscriptionsController < ApplicationController
      before_action :authenticate_request, except: [:success, :cancel]
      skip_before_action :verify_authenticity_token, only: [:create, :success, :cancel]

      def index
        subscriptions = Subscription.where(user_id: @current_user.id).order(created_at: :desc)
        updated_subscriptions = subscriptions.map do |sub|
          result = SubscriptionPaymentService.check_subscription_status(sub)
          result[:success] ? result[:subscription] : sub
        end
        render json: updated_subscriptions, status: :ok
      end

      def create
        result = SubscriptionPaymentService.process_payment(
          user: @current_user,
          plan: params[:plan]
        )

        if result[:success]
          render json: { checkout_url: result[:checkout_url] }, status: :created
        else
          render json: { error: result[:error] }, status: :unprocessable_entity
        end
      end

      def success
        user_id = params[:user_id]
        unless user_id
          render json: { error: 'User not authenticated' }, status: :unauthorized and return
        end

        user = User.find_by(id: user_id)
        unless user
          render json: { error: 'User not found' }, status: :not_found and return
        end

        plan = params[:plan]
        unless Subscription.plans.key?(plan)
          render json: { error: 'Invalid plan' }, status: :unprocessable_entity and return
        end

        result = SubscriptionPaymentService.complete_payment(
          user: user,
          session_id: params[:session_id],
          plan: plan
        )

        if result[:success]
          render json: {
            message: 'Subscription created successfully',
            subscription: result[:subscription]
          }, status: :created
        else
          render json: { error: result[:error] }, status: :unprocessable_entity
        end
      end

      def cancel
        render json: { message: 'Subscription creation cancelled' }, status: :ok
      end
    end
  end
end