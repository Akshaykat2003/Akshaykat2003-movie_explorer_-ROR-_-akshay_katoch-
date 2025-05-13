
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, unless: -> { request.format.json? }

  private

  def authenticate_request
    header = request.headers['Authorization']
    token = header&.split(/\s+/)&.last
    
    unless token
      render json: { error: 'Unauthorized: Missing token' }, status: :unauthorized
      return
    end

    begin
      decoded = JWT.decode(token, Rails.application.secrets.secret_key_base, true, { algorithm: 'HS256' })[0]
      @current_user = User.find(decoded['user_id'])
    rescue JWT::DecodeError => e
      render json: { error: "Unauthorized: Invalid token - #{e.message}" }, status: :unauthorized
      return
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Unauthorized: User not found' }, status: :unauthorized
      return
    rescue StandardError => e
      render json: { error: 'Internal server error' }, status: :internal_server_error
      return
    end
  end

  def current_user
    @current_user
  end
end