  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception, unless: -> { request.format.json? }
    before_action :authenticate_request
  
    attr_reader :current_user
    private
    def authenticate_request
      return if request.format.html?
      return if Rails.env.test?

      header = request.headers['Authorization']
      if header.present?
        token = header.split(' ').last
        @current_user = User.decode_jwt(token)
    
        unless @current_user
          render json: { error: 'Unauthorized' }, status: :unauthorized
        end
      else
        render json: { error: 'Authorization header missing' }, status: :unauthorized
      end
    end
  end
