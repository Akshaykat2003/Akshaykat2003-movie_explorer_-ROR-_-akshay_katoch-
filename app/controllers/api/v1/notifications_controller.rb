module Api
  module V1
    class NotificationsController < ApplicationController
      before_action :authenticate_request
      before_action :authorize_supervisor_or_admin
      skip_before_action :verify_authenticity_token

      def test
        tokens = User.where(notifications_enabled: true).where.not(device_token: nil).pluck(:device_token)
        return render json: { message: "No eligible devices" }, status: :ok if tokens.empty?

        FirebaseService.send_notification(
          tokens: tokens,
          title: "Test Notification",
          body: "This is a test notification from Movie Explorer+.",
          data: { test: "true" }
        )

        render json: { message: "Test notification sent" }, status: :ok
      rescue StandardError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

      def authorize_supervisor_or_admin
        unless @current_user&.role&.in?(['supervisor', 'admin'])
          render json: { error: "Forbidden" }, status: :forbidden
          return
        end
      end
    end
  end
end