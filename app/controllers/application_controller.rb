class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, unless: -> { request.format.json? }
  before_action :authenticate_request, unless: :active_admin_controller?

  private
  def authenticate_request
    Rails.logger.info("authenticate_request called for path: #{request.path}, controller: #{controller_path}")
    header = request.headers['Authorization']
    token = header&.split(/\s+/)&.last
    
    unless token
      Rails.logger.info("No token provided")
      render json: { error: 'Unauthorized: Missing token' }, status: :unauthorized
      return
    end

    begin
      decoded = JWT.decode(token, Rails.application.secrets.secret_key_base, true, { algorithm: 'HS256' })[0]
      @current_user = User.find(decoded['user_id'])
    rescue JWT::DecodeError => e
      Rails.logger.info("JWT Decode Error: #{e.message}")
      render json: { error: "Unauthorized: Invalid token - #{e.message}" }, status: :unauthorized
      return
    rescue ActiveRecord::RecordNotFound
      Rails.logger.info("User not found for token")
      render json: { error: 'Unauthorized: User not found' }, status: :unauthorized
      return
    rescue StandardError => e
      Rails.logger.info("Unexpected error: #{e.message}")
      render json: { error: 'Internal server error' }, status: :internal_server_error
      return
    end
  end

  def current_user
    @current_user
  end

  # Override Active Admin's Devise authentication
  def authenticate_admin_user!
    Rails.logger.info("authenticate_admin_user! called for path: #{request.path}, controller: #{controller_path} - Skipping authentication")
    # Do nothing, allowing access without authentication
    true
  end

  # Define current_admin_user to avoid errors
  def current_admin_user
    Rails.logger.info("current_admin_user called for path: #{request.path}, controller: #{controller_path} - Returning nil")
    nil # No user required for Active Admin
  end

  # Skip authorize_supervisor_or_admin if defined
  def authorize_supervisor_or_admin
    return if active_admin_controller?
    user_id = @current_user&.id || 'none'
    user_role = @current_user&.role || 'none'
    Rails.logger.info("Authorization check for user_id: #{user_id}, role: #{user_role}, action: #{action_name}")
    unless @current_user&.role&.in?(%w[supervisor admin])
      Rails.logger.info("Authorization failed for user_id: #{user_id}, role: #{user_role}, action: #{action_name}")
      render json: { error: "Forbidden: You do not have permission to perform this action" }, status: :forbidden
      return
    end
    Rails.logger.info("Authorization succeeded for user_id: #{user_id}, role: #{user_role}, action: #{action_name}")
  end

  def active_admin_controller?
    controller_path.start_with?('admin/')
  end
end