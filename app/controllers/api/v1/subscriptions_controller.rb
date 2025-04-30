module Api
  module V1
    class SubscriptionsController < ApplicationController
      before_action :authenticate_request
      before_action :set_subscription, only: [:show, :update, :destroy]

      # GET /api/v1/subscriptions
      def index
        subscriptions = Subscription.where(user_id: @current_user.id).order(created_at: :desc)
        render json: subscriptions, status: :ok
      end

      # GET /api/v1/subscriptions/:id
      def show
        render json: @subscription, status: :ok
      end

      # POST /api/v1/subscriptions
      def create
        subscription = SubscriptionPaymentService.process_payment(
          user: @current_user,
          plan: params[:plan],
          payment_params: { payment_id: params[:payment_id] } # Make sure frontend sends this
        )

        if subscription
          render json: subscription, status: :created
        else
          render json: { error: "Subscription creation/payment failed" }, status: :unprocessable_entity
        end
      end

      # PUT/PATCH /api/v1/subscriptions/:id
      def update
        if @subscription.update(subscription_params)
          render json: @subscription, status: :ok
        else
          render json: { errors: @subscription.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/subscriptions/:id
      def destroy
        if @subscription.destroy
          render json: { message: 'Subscription deleted successfully' }, status: :ok
        else
          render json: { error: 'Failed to delete subscription' }, status: :unprocessable_entity
        end
      end

      private

      def set_subscription
        @subscription = Subscription.find_by(id: params[:id], user_id: @current_user.id)
        unless @subscription
          render json: { error: 'Subscription not found' }, status: :not_found
        end
      end

      def subscription_params
        params.require(:subscription).permit(:plan, :status, :payment_id)
      end
    end
  end
end
