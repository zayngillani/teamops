class Api::V1::LeavesController < ApplicationController
  include Authentication
  include LeavesHelper 

  def create_leave
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])

    leave_data = calculate_leave_data(current_user)
    validation_error = validate_leave_params(params, start_date, end_date, current_user, leave_data)

    if validation_error
      render json: { error: validation_error[:error] }, status: :unprocessable_entity
      return
    end

    @leave = Leave.new(
      start_date: start_date,
      end_date: end_date,
      user_id: current_user.id,
      leave_type: params[:leave_type].to_i,
      reason: params[:reason]
    )

    if @leave.save
      SlackService.new(current_user, "Requested #{@leave.leave_type.capitalize} Leave for", @leave).request_leave
      render json: { success: "Leave request submitted successfully." , leave: @leave}, status: :ok
    else
      render json: { error: "Reason cannot be empty or contain only spaces." }, status: :unprocessable_entity
    end
  end

  def user_leaves_record
    @month, @year = get_month_and_year(params)
    @start_date, @end_date = get_date_range(@year, @month)
    @leaves = fetch_leaves(current_user.id, @year, @month, params[:page])
    current_year_start = Date.new(@start_date.year, 1, 1)
    current_year_end = Date.new(@end_date.year, 12, 31)

    @annual_leaves = annual_leaves(current_year_start, current_year_end)
    @quarterly_leaves = quarterly_leaves(@month, @year)
    @unused_quarterly_leaves = unused_quarterly_leaves(@year, current_user)

    @allotted_annual_leaves, @allotted_quarterly_leaves = allotted_leaves(current_user.join_date)
    @annual_count = (@unused_quarterly_leaves + @allotted_annual_leaves.to_i) - @annual_leaves
    @quarter_count = @allotted_quarterly_leaves.to_i - @quarterly_leaves
    leaves = Leave.for_month(@current_user.id, @month, @year)
    if leaves.present?
      render json: { success: true, message: 'Leave records fetched successfully', annual_leaves: @annual_count, quarter_leaves: @quarter_count, leaves: leaves }, status: :ok
    else
      render json: {success: false, message: 'No Leave records found for the selected month' }, status: :not_found
    end
  end
end