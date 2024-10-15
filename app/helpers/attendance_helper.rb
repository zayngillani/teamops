module AttendanceHelper
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
    join_date = user.join_date
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
