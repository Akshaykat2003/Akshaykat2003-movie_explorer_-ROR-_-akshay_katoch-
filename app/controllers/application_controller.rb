class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, unless: -> { request.format.json? }
  before_action :authenticate_request, unless: :active_admin_controller?

  private
  def authenticate_request
    header = request.headers['Authorization']
    token = header&.split(/\s+/)&.last
    unless token
      render json: { errors: ["Unauthorized: Missing token"] }, status: :unauthorized
      return
    end

    begin
      decoded = JWT.decode(token, Rails.application.secrets.secret_key_base, true, { algorithm: 'HS256' })[0]
      @current_user = User.find(decoded['user_id'])
    rescue JWT::DecodeError => e
      render json: { errors: ["Unauthorized: Invalid token - #{e.message}"] }, status: :unauthorized
      return
    rescue ActiveRecord::RecordNotFound
      render json: { errors: ["Unauthorized: User not found"] }, status: :unauthorized
      return
    rescue StandardError
      render json: { errors: ["Internal server error"] }, status: :internal_server_error
      return
    end
  end

  def current_user
    @current_user
  end

  def authenticate_admin_user!
    true
  end

  def current_admin_user
    nil
  end

  def authorize_supervisor_or_admin
    return if active_admin_controller?

    unless @current_user&.role&.in?(%w[supervisor admin])
      render json: { errors: ["Forbidden: You do not have permission to perform this action"] }, status: :forbidden
    end
  end

  def active_admin_controller?
    controller_path.start_with?('admin/')
  end
end