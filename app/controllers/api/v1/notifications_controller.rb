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

    result = FirebaseService.send_notification(
      tokens: [device_token],
      title: notification[:title],
      body: notification[:body]
    )

    if result[:success]
      render json: { message: "Notification sent successfully" }, status: :ok
    else
      render json: { error: "Invalid device token or FCM failure: #{result[:errors].join(', ')}" }, status: :unprocessable_entity
    end
  end

  private

  def authorize_supervisor_or_admin
    unless current_user&.admin? || current_user&.supervisor?
      render json: { error: "Forbidden: You do not have permission to perform this action" }, status: :forbidden
    end
  end
end