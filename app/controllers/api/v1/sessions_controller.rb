class Api::V1::SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token
  skip_before_action :require_no_authentication, only: [:create]
  skip_before_action :verify_signed_out_user, only: :destroy
  respond_to :json

  def create
    user = User.find_for_database_authentication(email: params[:email])
    if user && user.valid_password?(params[:password])
      user.generate_authentication_token
      user.save
      sign_in(user)
      attendance = Attendance.find_today_checkin(user)
      render json: { success: true, message: "Logged in successfully", user: user, token: user.authentication_token , attendance: attendance }, status: :ok
    else
      render json: { success: false, message: "Invalid email or password" }, status: :unauthorized
    end
  end

  def destroy
    if current_user
      current_user.update(authentication_token: nil)
      sign_out(current_user)
      render json: { success: true, message: "Logged out successfully" }, status: :ok
    else
      render json: { success: false, message: "No user logged in" }, status: :unauthorized
    end
  end
end
