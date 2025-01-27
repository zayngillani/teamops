module LeavesHelper
  
  def get_month_and_year(params)
    month = params[:month].present? ? params[:month].to_i : Date.today.month
    year = params[:year].present? ? params[:year].to_i : Date.today.year
    [month, year]
  end

  def get_date_range(year, month)
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month
    [start_date, end_date]
  end

  def fetch_leaves(user_id, year, month, page)
    Leave.where(user_id: user_id)
         .where("extract(year from start_date) = ? AND extract(month from start_date) = ?", year, month)
         .order(created_at: :desc)
         .paginate(page: page, per_page: 10)
  end

  def annual_leaves(current_year_start, current_year_end)
    calculate_annual_leaves_count(current_year_start, current_year_end)
  end

  def quarterly_leaves(month, year)
    calculate_quarterly_leaves(month, year)
  end

  def unused_quarterly_leaves(year, user)
    calculate_unused_quarterly_leaves(year, user)
  end

  def allotted_leaves(join_date)
    annual_leaves = join_date > 1.year.ago ? '0' : ENV['ANNUAL_LEAVE'].to_i
    quarterly_leaves = join_date > 3.months.ago ? '0' : ENV['QUATER_LEAVE'].to_i
    [annual_leaves, quarterly_leaves]
  end

  def calculate_leave_data(current_user)
    current_year_start = Date.current.beginning_of_year
    current_year_end = Date.current.end_of_year

    annual_leaves = calculate_annual_leaves_count(current_year_start, current_year_end)
    allotted_annual_leaves = current_user.join_date > 1.year.ago ? 0 : ENV['ANNUAL_LEAVE'].to_i
    unused_quarterly_leaves = calculate_unused_quarterly_leaves(Date.current.year, current_user)
    actual_leaves_count = (unused_quarterly_leaves + allotted_annual_leaves.to_i) - annual_leaves

    pending_leaves = Leave.where(user_id: current_user.id, leave_type: 1, status: 0).sum do |leave|
      (leave.end_date - leave.start_date).to_i + 1
    end

    { actual_leaves_count: actual_leaves_count, pending_leaves: pending_leaves }
  end

  def get_quarter_dates(date)
    case (date.month - 1) / 3
    when 0 then [Date.new(date.year, 1, 1), Date.new(date.year, 3, 31)]
    when 1 then [Date.new(date.year, 4, 1), Date.new(date.year, 6, 30)]
    when 2 then [Date.new(date.year, 7, 1), Date.new(date.year, 9, 30)]
    when 3 then [Date.new(date.year, 10, 1), Date.new(date.year, 12, 31)]
    end
  end

  def validate_leave_params(params, leave_start, leave_end, current_user, leave_data)
    leave_type = params[:leave_type].to_i
    leave_days = (leave_end - leave_start).to_i + 1

    return { error: "Please select leave type" } unless params[:leave_type].present?

    if leave_type == 2
      return { error: "Wedding leave must be exactly 10 consecutive days." } unless leave_days == 10

      previous_wedding_leave = Leave.where(user_id: current_user.id, leave_type: 2).where.not(status: 'rejected').exists?
      return { error: "You can only apply for wedding leave once." } if previous_wedding_leave
    end

    if leave_type == 1
      if leave_data[:pending_leaves] + leave_days > leave_data[:actual_leaves_count]
        return { error: "Insufficient leave balance. You cannot request leave exceeding your balance." }
      end
    end

    if [0, 1].include?(leave_type)
      leave_months = [leave_start.month, leave_end.month].uniq
      wedding_leave_exists = Leave.where(user_id: current_user.id)
                                   .where(leave_type: 2, status: [0, 1])
                                   .where("EXTRACT(YEAR FROM start_date) = ? AND (EXTRACT(MONTH FROM start_date) IN (?) OR EXTRACT(MONTH FROM end_date) IN (?))", leave_start.year, leave_months, leave_months)
                                   .exists?
      return { error: "You cannot apply for quarterly or annual leave in the same month as wedding leave." } if wedding_leave_exists
    end

    if leave_type == 1 && Date.today < (current_user.join_date + 3.months)
      return { error: "Leave requests are available only after 3 months of service." }
    end

    if leave_type == 0 && Date.today < (current_user.join_date + 3.months)
      return { error: "You must complete 3 months of employment before requesting quarterly leave." }
    end
    if !params[:leave_type] == 2
      if leave_includes_weekends?(leave_start, leave_end)
        return { error: "You cannot request leave including weekends." }
      end
    end

    if holiday_on_leave?(leave_start, leave_end)
      return { error: "You can't request leave on a public holiday" }
    end

    if leave_start == Date.today
      return { error: "You cannot request leave for today. Please select a future date." }
    end

    if leave_start > leave_end
      return { error: "End date must be greater than or equal to start date" }
    end

    if overlapping_leave?(current_user.id, leave_start, leave_end)
      return { error: "Leave already submitted for the selected dates" }
    end

    if leave_type != 2
      quarter_dates = get_quarter_dates(leave_start)

      if exceeds_annual_leave_limit?(current_user, leave_type, leave_days, quarter_dates.first.beginning_of_year, quarter_dates.first.end_of_year)
        return { error: "You have exceeded the maximum annual leave limit of 8 days per year" }
      end

      if exceeds_quarterly_leave_limit?(current_user.id, leave_type, leave_days, quarter_dates.first, quarter_dates.last)
        return { error: "You cannot request more than 3 days of leave per quarter." }
      end
    end

    nil
  end

  def leave_includes_weekends?(start_date, end_date)
    (start_date..end_date).any? { |date| date.saturday? || date.sunday? }
  end

  def holiday_on_leave?(start_date, end_date)
    PublicHoliday.exists?(start_date: start_date..end_date)
  end

  def overlapping_leave?(user_id, start_date, end_date)
    Leave.exists?(user_id: user_id, status: [0, 1], start_date: ..end_date, end_date: start_date..)
  end

  def exceeds_annual_leave_limit?(user, leave_type, leave_days, year_start, year_end)
    return false unless leave_type == 1

    annual_leave_limit = if user.join_date > 1.year.ago
                           calculate_unused_quarterly_leaves(year_start.year, user) - calculate_annual_leaves_count(year_start, year_end)
                         else
                           ENV['ANNUAL_LEAVE'].to_i
                         end
    leave_days > annual_leave_limit
  end

  def exceeds_quarterly_leave_limit?(user_id, leave_type, leave_days, quarter_start, quarter_end)
    return false unless leave_type == 0

    existing_quarterly_leave_days = Leave.where(
      user_id: user_id,
      leave_type: 0,
      status: [0, 1],
      start_date: quarter_start..quarter_end
    ).sum { |leave| (leave.end_date - leave.start_date).to_i + 1 }

    existing_quarterly_leave_days + leave_days > ENV['QUATER_LEAVE'].to_i
  end

  def calculate_annual_leaves_count(current_year_start, current_year_end)
    annual_leaves = Leave.where(user_id: current_user.id, leave_type: 1, status: 1)
                         .where("start_date >= ? AND start_date <= ?", current_year_start, current_year_end)
    annual_leaves&.sum do |leave|
      (leave.end_date - leave.start_date).to_i + 1
    end
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
    @quarterly_leaves = @quarterly&.sum do |leave|
      (leave.end_date - leave.start_date).to_i + 1
    end
  end

  def calculate_unused_quarterly_leaves(year, user)
    unused_leaves = 0
    join_date = user&.join_date
    return if join_date.nil?

    three_months_from_join_date = join_date + 3.months  
    return unused_leaves if Date.today < three_months_from_join_date
    quarters = if year == 2024
                 {
                   Q2: { start: Date.new(year, 4, 1), end: Date.new(year, 6, 30) },
                   Q3: { start: Date.new(year, 7, 1), end: Date.new(year, 9, 30) },
                   Q4: { start: Date.new(year, 10, 1), end: Date.new(year, 12, 31) }
                 }
               else
                 {
                   Q1: { start: Date.new(year, 1, 1), end: Date.new(year, 3, 31) },
                   Q2: { start: Date.new(year, 4, 1), end: Date.new(year, 6, 30) },
                   Q3: { start: Date.new(year, 7, 1), end: Date.new(year, 9, 30) },
                   Q4: { start: Date.new(year, 10, 1), end: Date.new(year, 12, 31) }
                 }
               end  
    quarters.each do |quarter, range|
      next if range[:end] < join_date   
      if Date.today > range[:end]
        quarterly_leaves = Leave.where(user_id: current_user.id, leave_type: 0, status: 1)
                                .where("start_date >= ? AND end_date <= ?", [range[:start], join_date].max, range[:end])
                                .sum { |leave| (leave.end_date - leave.start_date).to_i + 1 }  
        unused_leaves += [3 - quarterly_leaves, 0].max
      end
    end
    unused_leaves
  end
end