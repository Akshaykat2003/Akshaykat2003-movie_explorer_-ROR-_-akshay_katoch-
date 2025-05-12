# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, unless: -> { request.format.json? }
  before_action :authenticate_request

  private

  def authenticate_request
    return if request.format.html?

    header = request.headers['Authorization']
    if header.present?
      token = header.split(' ').last
      if BlacklistedToken.blacklisted?(token)
        render json: { error: 'Token has been invalidated. Please log in again.' }, status: :unauthorized
        return
      end

      @current_user = User.decode_jwt(token)
      unless @current_user
        render json: { error: 'Unauthorized' }, status: :unauthorized
        return
      end
    else
      render json: { error: 'Authorization header missing' }, status: :unauthorized
      return
    end
  end

  def current_user
    @current_user
  end
end