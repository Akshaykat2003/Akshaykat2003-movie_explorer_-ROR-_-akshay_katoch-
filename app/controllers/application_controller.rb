
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, unless: -> { request.format.json? }
  before_action :authenticate_request

  private

  def authenticate_request
    header = request.headers['Authorization']
    Rails.logger.info("Authenticate_request - Raw Authorization Header: #{header.inspect}")
    token = header&.split(/\s+/)&.last
    Rails.logger.info("Authenticate_request - Parsed Token: #{token || 'none'}")
    
    unless token
      Rails.logger.info("Authenticate_request - No token provided")
      render json: { error: 'Unauthorized: Missing token' }, status: :unauthorized
      return
    end

    begin
      decoded = JWT.decode(token, Rails.application.secrets.secret_key_base, true, { algorithm: 'HS256' })[0]
      Rails.logger.info("Authenticate_request - JWT Decoded: #{decoded.inspect}")
      @current_user = User.find(decoded['user_id'])
      Rails.logger.info("Authenticate_request - Authenticated user_id: #{@current_user.id}, role: #{@current_user.role}")
    rescue JWT::DecodeError => e
      Rails.logger.info("Authenticate_request - JWT Decode Error: #{e.message}")
      render json: { error: "Unauthorized: Invalid token - #{e.message}" }, status: :unauthorized
      return
    rescue ActiveRecord::RecordNotFound
      Rails.logger.info("Authenticate_request - User not found for token")
      render json: { error: 'Unauthorized: User not found' }, status: :unauthorized
      return
    rescue StandardError => e
      Rails.logger.info("Authenticate_request - Unexpected error: #{e.message}")
      render json: { error: 'Internal server error' }, status: :internal_server_error
      return
    end
  end

  def current_user
    @current_user
  end
end