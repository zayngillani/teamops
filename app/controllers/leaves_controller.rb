class LeavesController < ApplicationController
  def index
    @month = params[:month].present? ? params[:month].to_i : Date.today.month
    @year = params[:year].present? ? params[:year].to_i : Date.today.year
    @start_date = Date.new(@year, @month, 1)
    @end_date = @start_date.end_of_month
    current_month_start = @start_date.beginning_of_month
    current_month_end = @end_date.end_of_month
    @leaves = Leave.where(user_id: current_user.id)
    .where("start_date >= ? AND start_date <= ?", current_month_start, current_month_end)
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
    leave_start = Date.parse(params[:start_date])
    leave_end = Date.parse(params[:end_date])
    current_month_start = Date.today.beginning_of_month
    current_month_end = Date.today.end_of_month
    next_month_start = current_month_start.next_month
    next_month_end = current_month_end.next_month
    leaves_current_month = Leave.where(user_id: current_user.id)
    .where("start_date >= ? AND start_date <= ?", current_month_start, current_month_end)
    .count
    leaves_next_month = Leave.where(user_id: current_user.id)
    .where("start_date >= ? AND start_date <= ?", next_month_start, next_month_end)
    .count
    holiday = PublicHoliday.find_by(start_date: start_date..end_date)
    if start_date.present?
      if leave_start > next_month_end
        redirect_to leaves_path, flash: { error: "You cannot request leaves for future months" }
        return
      elsif leave_start.between?(current_month_start, current_month_end)
        if leaves_current_month >= 2
          redirect_to leaves_path, flash: { error: "You can only request two leaves in the current month" }
          return
        end
      elsif leave_start.between?(next_month_start, next_month_end)
        if leaves_next_month >= 2
          redirect_to leaves_path, flash: { error: "You can only request two leaves in the next month" }
          return
        end
      end
    end
    if (leave_start..leave_end).any? { |date| date.saturday? || date.sunday? }
      redirect_to leaves_path, flash: { error: "You cannot request leave including weekends." }
      return
    end
    if leave_start.saturday? || leave_start.sunday? || leave_end.saturday? || leave_end.sunday?
      redirect_to leaves_path, flash: { error: "You can't request leave for weekends (Saturday or Sunday)." }
      return
    end
    if leave_start == Date.today
      redirect_to leaves_path, flash: { error: "You cannot request leave for today. Please select a future date." }
      return
    end
    if params[:start_date] > params[:end_date]
      redirect_to leaves_path, flash: { error: "End date must be greater than or equal to start date" }
      return
    end
    if holiday.present?
      redirect_to leaves_path, flash: { error: "You can't request for Leave on Public Holiday" }
      return
    end
    if Leave.exists?(user_id: current_user.id, status: [0, 1, 2], start_date: ..start_date, end_date: end_date..)
      redirect_to leaves_path, flash: { error: "Leave Already Submitted" }
      return
    end
    @leave = Leave.new
    @leave.start_date = params[:start_date]
    @leave.end_date = params[:end_date]
    @leave.user_id = current_user.id
    @leave.leave_type = params[:leave_type].to_i
    @leave.reason = params[:reason]
    if @leave.save
      # SlackService.new(current_user, "Request leave from", @leave).request_leave
      flash[:success] = 'Leave Request submitted'
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
end
