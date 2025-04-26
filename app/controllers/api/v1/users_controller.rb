class Api::V1::UsersController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_request, only: [:signup, :login]

  def signup
    params[:role] = 'user' unless params[:role] 
    
    result = User.register(user_params)
    
    if result[:success]
      user = result[:user]
      render json: { message: "Signup successful", user: user.as_json(except: [:password_digest]) }, status: :created
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end

  def login
    
    user = User.authenticate(params[:email], params[:password])
    if user
      token = user.generate_jwt
      render json: { token: token, user: { id: user.id, name: "#{user.first_name} #{user.last_name}", email: user.email } }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  private

  def user_params
    params.permit(:first_name, :last_name, :email, :password, :mobile_number)
  end
end
