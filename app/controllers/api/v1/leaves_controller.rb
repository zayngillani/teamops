class Api::V1::LeavesController < ApplicationController
  include Authentication

  def user_leaves_record
    month = params[:month] || Date.today.month
    year = params[:year] || Date.today.year
    leaves = Leave.for_month(@current_user.id, month, year)
    if leaves.present?
      render json: { success: true, message: 'Leave records fetched successfully', leaves: leaves }, status: :ok
    else
      render json: {success: false, message: 'No Leave records found for the selected month' }, status: :not_found
    end
  end
end