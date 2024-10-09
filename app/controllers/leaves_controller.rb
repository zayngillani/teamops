class LeavesController < ApplicationController
  def index
    @month = params[:month].present? ? params[:month].to_i : Date.today.month
    @year = params[:year].present? ? params[:year].to_i : Date.today.year
    @start_date = Date.new(@year, @month, 1)
    @end_date = @start_date.end_of_month
    current_month_start = @start_date.beginning_of_month
    current_month_end = @end_date.end_of_month
    @leaves = Leave.where(user_id: current_user.id)
               .where("extract(year from start_date) = ? AND extract(month from start_date) = ?", @year, @month)
               .order(created_at: :desc)
               .paginate(page: params[:page], per_page: 10)
    current_year_start = Date.new(@start_date.year, 1, 1)
    current_year_end = Date.new(@end_date.year, 12, 31)
    @annual_leaves = Leave.where(user_id: current_user.id, leave_type: 1, status: 1)
    .where("start_date >= ? AND start_date <= ?", current_year_start, current_year_end)
    @annual_leaves = @annual_leaves.sum do |leave|
      (leave.end_date - leave.start_date).to_i + 1
    end
    @quarterly_leaves = calculate_quarterly_leaves(@month , @year)
    @unused_quarterly_leaves = calculate_unused_quarterly_leaves(@year)
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
    one_year_anniversary = current_user.join_date + 3.months
    restricted_period_end = Date.today + 3.days
    quarterly_restricted = current_user.join_date + 3.months
    if !params[:leave_type].present?
      redirect_to leaves_path, flash: { error: "Please select leave type" }
      return
    end  
    if params[:leave_type].to_i == 2
      unless leave_days == 10
        redirect_to leaves_path, flash: { error: "Wedding leave must be exactly 10 consecutive days." }
        return
      end  
      previous_wedding_leave = Leave.where(user_id: current_user.id, leave_type: 2).where.not(status: 'rejected').exists?
      if previous_wedding_leave
        redirect_to leaves_path, flash: { error: "You can only apply for wedding leave once." }
        return
      end
    else
      if params[:leave_type].to_i == 0 || params[:leave_type].to_i == 1
        leave_months = [leave_start.month, leave_end.month].to_a.uniq
        wedding_leave_exists = Leave.where(user_id: current_user.id)
        .where(leave_type: 2)
        .where("EXTRACT(YEAR FROM start_date) = ? AND (EXTRACT(MONTH FROM start_date) IN (?) OR EXTRACT(MONTH FROM end_date) IN (?))", leave_start.year, leave_months, leave_months).exists?
        if wedding_leave_exists
          redirect_to leaves_path, flash: { error: "You cannot apply for quarterly or annual leave in the same month as wedding leave." }
          return
        end
      end
      if Date.today < one_year_anniversary && params[:leave_type].to_i == 1
        redirect_to leaves_path, flash: { error: "Leave requests are available only after 3 months of service." }
        return
      end
      if leave_start.between?(Date.today, restricted_period_end) && params[:leave_type].to_i == 1
        redirect_to leaves_path, flash: { error: "You can only apply for annual leaves starting 3 Days before." }
        return
      end
      if Date.today < quarterly_restricted && params[:leave_type].to_i == 0
        redirect_to leaves_path, flash: { error: "You must complete 3 months of employment before requesting quarterly leave." }
        return
      end
      if leave_includes_weekends?(leave_start, leave_end)
        redirect_to leaves_path, flash: { error: "You cannot request leave including weekends." }
        return
      end
      if holiday_on_leave?(leave_start, leave_end)
        redirect_to leaves_path, flash: { error: "You can't request leave on a public holiday" }
        return
      end
    end
    if invalid_leave_dates?(leave_start, leave_end)
      redirect_to leaves_path, flash: { error: "Invalid leave dates" }
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
    if overlapping_leave?(leave_start, leave_end)
      redirect_to leaves_path, flash: { error: "Leave already submitted for the selected dates" }
      return
    end
    unless params[:leave_type].to_i == 2
      if exceeds_annual_leave_limit?(params[:leave_type].to_i, leave_days, current_year_start, current_year_end)
        redirect_to leaves_path, flash: { error: "You have exceeded the maximum annual leave limit of 8 days per year" }
        return
      end
      if exceeds_quarterly_leave_limit?(params[:leave_type].to_i, leave_days, current_quarter_start, current_quarter_end)
        redirect_to leaves_path, flash: { error: "You cannot request more than 3 days of leave per quarter." }
        return
      end
    end
  
    @leave = Leave.new(
      start_date: leave_start,
      end_date: leave_end,
      user_id: current_user.id,
      leave_type: params[:leave_type].to_i,
      reason: params[:reason]
    )
    if @leave.save
      flash[:success] = 'Leave request submitted.'
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

  def calculate_quarterly_leaves(month , year)
    current_year = year
    current_month = month
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
    Leave.exists?(user_id: current_user.id, status: [0, 1], start_date: ..end_date, end_date: start_date..)
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

  def calculate_unused_quarterly_leaves(year)
    unused_leaves = 0
    quarters = {
      Q1: { start: Date.new(year, 1, 1), end: Date.new(year, 3, 31) },
      Q2: { start: Date.new(year, 4, 1), end: Date.new(year, 6, 30) },
      Q3: { start: Date.new(year, 7, 1), end: Date.new(year, 9, 30) },
      Q4: { start: Date.new(year, 10, 1), end: Date.new(year, 12, 31) }
    }
    quarters.each do |quarter, range|
      next unless Date.today > range[:end]  
      quarterly_leaves = Leave.where(user_id: current_user.id, leave_type: 0, status: 1)
                             .where("start_date >= ? AND end_date <= ?", range[:start], range[:end])
                             .sum { |leave| (leave.end_date - leave.start_date).to_i + 1 }
      if quarterly_leaves < 3
        unused_leaves += (3 - quarterly_leaves)
      end
    end
    unused_leaves
  end
end
