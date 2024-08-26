class LeavesController < ApplicationController
  def index
    @month = params[:month].present? ? params[:month].to_i : Date.today.month
    @year = params[:year].present? ? params[:year].to_i : Date.today.year
    @start_date = Date.new(@year, @month, 1)
    @end_date = @start_date.end_of_month
    current_month_start = @start_date.beginning_of_month
    current_month_end = @end_date.end_of_month
    @leaves = Leave.where(user_id: current_user.id)
    .order(created_at: :desc).paginate(page: params[:page], per_page: 10)
    current_year_start = Date.new(@start_date.year, 1, 1)
    current_year_end = Date.new(@end_date.year, 12, 31)
    @annual_leaves = Leave.where(user_id: current_user.id, leave_type: 1, status: 1)
    .where("start_date >= ? AND start_date <= ?", current_year_start, current_year_end)
    @annual_leaves = @annual_leaves.sum do |leave|
      (leave.end_date - leave.start_date).to_i + 1
    end
    @quarterly_leaves = calculate_quarterly_leaves
  end

  def new
    @leaves = current_user.leaves
  end
  
  def create
    start_date = params[:start_date]
    end_date = params[:end_date]
    leave_start = Date.parse(start_date)
    leave_end = Date.parse(end_date)
    current_date = Date.today
    current_year_start = Date.new(current_date.year, 1, 1)
    current_year_end = Date.new(current_date.year, 12, 31)
    leave_days = (leave_end - leave_start).to_i + 1
    current_quarter_start, current_quarter_end = get_quarter_dates(leave_start)
    if invalid_leave_dates?(leave_start, leave_end)
      redirect_to leaves_path, flash: { error: "Invalid leave dates" }
      return
    end
    if leave_includes_weekends?(leave_start, leave_end)
      redirect_to leaves_path, flash: { error: "You cannot request leave including weekends." }
      return
    end
    if leave_start == Date.today
      redirect_to leaves_path, flash: { error: "You cannot request leave for today. Please select a future date." }
      return
    end
    if leave_start > leave_end
      redirect_to leaves_path, flash: { error: "End date must be greater than or equal to start date" }
      return
    end
    if holiday_on_leave?(leave_start, leave_end)
      redirect_to leaves_path, flash: { error: "You can't request leave on a public holiday" }
      return
    end
    if overlapping_leave?(leave_start, leave_end)
      redirect_to leaves_path, flash: { error: "Leave already submitted for the selected dates" }
      return
    end
    if exceeds_annual_leave_limit?(params[:leave_type].to_i, leave_days, current_year_start, current_year_end)
      redirect_to leaves_path, flash: { error: "You have exceeded the maximum annual leave limit of 9 days per year" }
      return
    end
    if exceeds_quarterly_leave_limit?(params[:leave_type].to_i, leave_days, current_quarter_start, current_quarter_end)
      redirect_to leaves_path, flash: { error: "You cannot request more than 3 days of leave per quarter." }
      return
    end
    @leave = Leave.new
    @leave.start_date = leave_start
    @leave.end_date = leave_end
    @leave.user_id = current_user.id
    @leave.leave_type = params[:leave_type].to_i
    @leave.reason = params[:reason]
    if @leave.save
      flash[:success] = 'Leave request submitted'
      redirect_to leaves_path
    else
      render :new
    end
  end

  private

  def leave_params
    params.require(:leaves).permit(:start_date, :end_date, :reason)
  end

  def calculate_quarterly_leaves
    current_year = Date.current.year
    current_month = Date.current.month
    case current_month
    when 1..3
      quarter_start = Date.new(current_year, 1, 1)
      quarter_end = Date.new(current_year, 3, 31)
    when 4..6
      quarter_start = Date.new(current_year, 4, 1)
      quarter_end = Date.new(current_year, 6, 30)
    when 7..9
      quarter_start = Date.new(current_year, 7, 1)
      quarter_end = Date.new(current_year, 9, 30)
    when 10..12
      quarter_start = Date.new(current_year, 10, 1)
      quarter_end = Date.new(current_year, 12, 31)
    end
    @quarterly = Leave.where(user_id: current_user.id, leave_type: 0, status: 1)
                              .where("start_date >= ? AND start_date <= ?", quarter_start, quarter_end)
    @quarterly_leaves = @quarterly.sum do |leave|
      (leave.end_date - leave.start_date).to_i + 1
    end
  end

  def get_quarter_dates(date)
    case (date.month - 1) / 3
    when 0 then [Date.new(date.year, 1, 1), Date.new(date.year, 3, 31)]
    when 1 then [Date.new(date.year, 4, 1), Date.new(date.year, 6, 30)]
    when 2 then [Date.new(date.year, 7, 1), Date.new(date.year, 9, 30)]
    when 3 then [Date.new(date.year, 10, 1), Date.new(date.year, 12, 31)]
    end
  end
  
  def invalid_leave_dates?(start_date, end_date)
    start_date.nil? || end_date.nil?
  end
  
  def leave_includes_weekends?(start_date, end_date)
    (start_date..end_date).any? { |date| date.saturday? || date.sunday? }
  end
  
  def holiday_on_leave?(start_date, end_date)
    PublicHoliday.exists?(start_date: start_date..end_date)
  end
  
  def overlapping_leave?(start_date, end_date)
    Leave.exists?(user_id: current_user.id, status: [0, 1, 2], start_date: ..end_date, end_date: start_date..)
  end
  
  def exceeds_annual_leave_limit?(leave_type, leave_days, year_start, year_end)
    return false unless leave_type == 1
  
    annual_leaves_count = Leave.where(
      user_id: current_user.id,
      leave_type: 1,
      status: [0, 1],
      start_date: year_start..year_end
    ).sum { |leave| (leave.end_date - leave.start_date).to_i + 1 }
  
    annual_leaves_count + leave_days > ENV["ANNUAL_LEAVE"].to_i
  end
  
  def exceeds_quarterly_leave_limit?(leave_type, leave_days, quarter_start, quarter_end)
    return false unless leave_type == 0
    existing_quarterly_leave_days = Leave.where(
      user_id: current_user.id,
      leave_type: 0,
      status: [0, 1],
      start_date: quarter_start..quarter_end
    ).sum { |leave| (leave.end_date - leave.start_date).to_i + 1 }
    existing_quarterly_leave_days + leave_days > ENV["QUATER_LEAVE"].to_i
  end
end
