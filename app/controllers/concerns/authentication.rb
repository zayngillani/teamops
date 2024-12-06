module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user_from_token!
  end

  private

  def authenticate_user_from_token!
    token = request.headers['Authorization']&.split(' ')&.last || params[:access_token]
    @current_user = User.find_by(authentication_token: token)
    unless @current_user
      render json: { success: false, error: 'Invalid or missing token' }, status: :unauthorized
    end
  end
end