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
      render json: { errors: ["Invalid email or password"] }, status: :unauthorized
    end
  end

  def update_preferences
    unless current_user
      render json: { errors: ["Authentication required"] }, status: :unauthorized
      return
    end
    update_params = params.permit(:device_token, :notifications_enabled)
    result = User.update_preferences(current_user, update_params)
    if result[:success]
      render json: { message: result[:message], user: result[:user]&.as_json_with_plan }, status: :ok
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end

 def logout
  token = request.headers['Authorization']&.split(' ')&.last
  result = BlacklistedToken.blacklist(token, Rails.application.credentials.secret_key_base)
  if result[:success]
    current_user.update(device_token: nil) if current_user
    render json: { message: result[:message] }, status: :ok
  else
    status = result[:error] == 'Token is missing' ? :unauthorized : :unprocessable_entity
    render json: { errors: [result[:error]] }, status: status
  end
end

  private

  def user_params
    params.permit(:first_name, :last_name, :email, :password, :mobile_number)
  end
end