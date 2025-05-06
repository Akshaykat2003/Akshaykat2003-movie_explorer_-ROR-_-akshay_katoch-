# app/controllers/api/v1/users_controller.rb
class Api::V1::UsersController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_request, only: [:signup, :login]

  def signup
    result = User.register(user_params.merge(role: 'user'))
    if result[:success]
      user = result[:user]
      token = user.generate_jwt
      render json: {
        message: "Signup successful",
        token: token,
        user: user.as_json(except: [:password_digest]).merge(role: user.role)
      }, status: :created
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end

  def login
    user = User.authenticate(params[:email], params[:password])
    if user
      token = user.generate_jwt
      render json: {
        token: token,
        user: {
          id: user.id,
          name: "#{user.first_name} #{user.last_name}",
          email: user.email,
          role: user.role
        }
      }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  def update_preferences
    unless current_user
      Rails.logger.warn("Failed to update preferences: No authenticated user found")
      render json: { errors: ["Authentication required"] }, status: :unauthorized
      return
    end

    update_params = params.permit(:device_token, :notifications_enabled).to_h
    update_params[:notifications_enabled] = update_params[:notifications_enabled] != false if update_params.key?(:notifications_enabled)

    if current_user.update(update_params)
      Rails.logger.info("User #{current_user.id} updated preferences: device_token=#{current_user.device_token}, notifications_enabled=#{current_user.notifications_enabled}")
      render json: { message: "Preferences updated successfully" }, status: :ok
    else
      Rails.logger.warn("Failed to update preferences for user #{current_user.id}: #{current_user.errors.full_messages.join(', ')}")
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error("Error in UsersController#update_preferences: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    render json: { errors: ["Internal server error"] }, status: :internal_server_error
  end


  def logout
    token = request.headers['Authorization']&.split(' ')&.last
    secret_key = Rails.application.credentials.secret_key_base

    result = BlacklistedToken.blacklist(token, secret_key)
    if result[:success]
      render json: { message: result[:message] }, status: :ok
    else
      status = result[:error] == 'Authorization header missing' ? :unauthorized : :unprocessable_entity
      render json: { error: result[:error] }, status: status
    end
  end

  private


  def user_params
    params.permit(:first_name, :last_name, :email, :password, :mobile_number)
  end
end