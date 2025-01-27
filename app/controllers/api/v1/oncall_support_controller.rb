class Api::V1::OncallSupportController < ApplicationController
  include OncallHelper
  include Authentication

  def create_oncall
    start_date = params[:start_date].to_date
    end_date = params[:end_date].to_date

    unless valid_date_range?(start_date, end_date)
      render json: { error: "End date must be greater than or equal to start date" }, status: :unprocessable_entity
      return
    end
    if oncall_exists?(current_user.id, start_date, end_date)
      render json: { error: "Oncall Already Submitted" }, status: :unprocessable_entity
      return
    end

    leaves = approved_leaves(current_user.id, start_date, end_date)
    holidays = public_holidays(start_date, end_date)

    (start_date..end_date).each do |date|
      unless valid_oncall_date?(date, holidays, leaves)
        render json: { error: "On-call requests are only allowed on holidays, weekends, or during approved leave." }, status: :unprocessable_entity
        return
      end
    end

    oncall = Oncall.new(
      start_date: params[:start_date],
      end_date: params[:end_date],
      reason: params[:reason],
      user_id: current_user.id
    )

    if oncall.save
      render json: { message: "On Call Support Request Submitted", oncall: oncall }, status: :created
    else
      render json: { error: "Reason cannot be empty or contain only spaces." }, status: :unprocessable_entity
    end
  end

  def user_oncalls_record
    month = (params[:month] || Date.today.month).to_i
    year = (params[:year] || Date.today.year).to_i
    oncalls = Oncall.for_month(@current_user.id, month, year)
    if oncalls.present?
      render json: { success: true, message: 'Oncall Support records fetched successfully', oncalls: oncalls }, status: :ok
    else
      render json: {success: false, message: 'No Oncall Support records found for the selected month' }, status: :not_found
    end
  end
end