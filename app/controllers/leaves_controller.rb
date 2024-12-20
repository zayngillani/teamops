class LeavesController < ApplicationController
  include AttendanceHelper
  include LeavesHelper 
  def index
    @month, @year = get_month_and_year(params)
    @start_date, @end_date = get_date_range(@year, @month)
    @leaves = fetch_leaves(current_user.id, @year, @month, params[:page])
    current_year_start = Date.new(@start_date.year, 1, 1)
    current_year_end = Date.new(@end_date.year, 12, 31)

    @annual_leaves = annual_leaves(current_year_start, current_year_end)
    @quarterly_leaves = quarterly_leaves(@month, @year)
    @unused_quarterly_leaves = unused_quarterly_leaves(@year, current_user)

    @allotted_annual_leaves, @allotted_quarterly_leaves = allotted_leaves(current_user.join_date)
  end

  def new
    @leaves = current_user.leaves
  end
  
  def create
    start_date = Date.parse(params[:start_date])
    end_date = Date.parse(params[:end_date])

    leave_data = calculate_leave_data(current_user)
    validation_error = validate_leave_params(params, start_date, end_date, current_user, leave_data)

    if validation_error
      redirect_to leaves_path, flash: { error: validation_error[:error] }
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
      flash[:success] = "#{@leave.leave_type.capitalize} Leave request submitted."
      SlackService.new(current_user, "Requested #{@leave.leave_type.capitalize} Leave for", @leave).request_leave
      redirect_to leaves_path
    else
      flash[:error] = "Reason cannot be empty or contain only spaces."
      redirect_to leaves_path
    end
  end

  private

  def leave_params
    params.require(:leaves).permit(:start_date, :end_date, :reason)
  end

end
