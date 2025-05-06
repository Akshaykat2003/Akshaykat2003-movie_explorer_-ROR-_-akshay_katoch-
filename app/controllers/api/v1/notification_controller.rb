class Api::V1::NotificationsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_supervisor_or_admin

  def send_fcm
    device_token = params[:device_token]
    notification = params[:notification]

    unless device_token && notification && notification[:title] && notification[:body]
      render json: { error: "Device token and notification (title and body) are required" }, status: :unprocessable_entity
      return
    end

    begin
      message = {
        token: device_token,
        notification: {
          title: notification[:title],
          body: notification[:body]
        }
      }

      fcm = FCM.new 
      response = fcm.send([message])

      if response[:success] == 1
        render json: { message: "Notification sent successfully" }, status: :ok
      else
        render json: { error: "Failed to send notification: #{response[:error]}" }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error("FCM error: #{e.message}")
      render json: { error: "Invalid device token or FCM failure" }, status: :unprocessable_entity
    end
  end

  private

  def authorize_supervisor_or_admin
    unless current_user.admin? || current_user.supervisor?
      render json: { error: "Forbidden: You do not have permission to perform this action" }, status: :forbidden
    end
  end
end