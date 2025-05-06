module Api
  module V1
    class NotificationsController < ApplicationController
      before_action :authenticate_request
      before_action :authorize_supervisor_or_admin
      skip_before_action :verify_authenticity_token

      def send_notification
        unless notification_params[:device_token] && notification_params[:notification]
          render json: { error: "Missing required parameters: device_token and notification are required" }, status: :bad_request
          return
        end
                
        result = FirebaseService.send_notification(
          tokens: [notification_params[:device_token]],
          title: notification_params[:notification][:title],
          body: notification_params[:notification][:body],
          data: notification_params[:data] || {}
        )

        if result[:success]
          Rails.logger.info("Notification sent successfully to device_token: #{notification_params[:device_token]}")
          render json: { message: "Notification sent successfully" }, status: :ok
        else
          Rails.logger.warn("Failed to send notification to device_token: #{notification_params[:device_token]}: #{result[:errors].join(', ')}")
          render json: { error: result[:errors] }, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error("Error in NotificationsController#send_notification: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        render json: { error: "Internal server error" }, status: :internal_server_error
      end

      private

      def notification_params
        params.permit(:device_token, notification: [:title, :body], data: {})
      end

      def authorize_supervisor_or_admin
        unless @current_user&.role&.in?(['supervisor', 'admin'])
          render json: { error: 'Forbidden: You do not have permission to perform this action' }, status: :forbidden
          return
        end
      end
    end
  end
end