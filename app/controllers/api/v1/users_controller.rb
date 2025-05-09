class Api::V1::UsersController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_request, only: [:signup, :login]

  def signup
    result = User.register(user_params.merge(role: 'user'))
    if result[:success]
      user = result[:user]
      subscription = Subscription.create_default_for_user(user)
      if subscription
        token = user.generate_jwt
        render json: { message: "Signup successful", token: token, user: user.as_json_with_plan }, status: :created
      else
        user.destroy
        render json: { errors: ["Failed to assign default plan"] }, status: :unprocessable_entity
      end
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end

  def login
    user = User.authenticate(params[:email], params[:password])
    if user
      token = user.generate_jwt
      render json: { token: token, user: user.as_json_with_plan }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  def update_preferences
    render json: { errors: ["Authentication required"] }, status: :unauthorized unless current_user

    update_params = params.permit(:device_token, :notifications_enabled).to_h
    update_params[:notifications_enabled] = update_params[:notifications_enabled] != false if update_params.key?(:notifications_enabled)
    update_params.delete(:device_token) if update_params[:device_token] && current_user.device_token == update_params[:device_token]

    if update_params.empty?
      render json: { message: "Preferences unchanged" }, status: :ok
    elsif current_user.update(update_params)
      render json: { message: "Preferences updated successfully" }, status: :ok
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotUnique
    render json: { errors: ["Device token is already in use by another user"] }, status: :unprocessable_entity
  rescue StandardError
    render json: { errors: ["Internal server error"] }, status: :internal_server_error
  end

  def logout
    token = request.headers['Authorization']&.split(' ')&.last
    result = BlacklistedToken.blacklist(token, Rails.application.credentials.secret_key_base)
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