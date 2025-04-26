class ApplicationController < ActionController::Base
  before_action :authenticate_request

  attr_reader :current_user

  private

  def authenticate_request
  
    return if request.format.html?
  
    header = request.headers['Authorization']
    token = header.split(' ').last if header.present?
    @current_user = User.decode_jwt(token)
  
    unless @current_user
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end  
end
