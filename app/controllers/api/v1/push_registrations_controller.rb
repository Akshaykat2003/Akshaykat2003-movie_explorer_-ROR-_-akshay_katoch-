module Api
  module V1
    class PushRegistrationsController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_request

      def create
        @current_user.update!(device_token: params[:device_token], notifications_enabled: params[:notifications_enabled] != false)
        render json: { message: "Device token registered successfully" }, status: :ok
      rescue StandardError => e
        Rails.logger.error("PushRegistrationsController#create error: #{e.message}")
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end
  end
end