module OncallHelper
  def valid_date_range?(start_date, end_date)
    start_date <= end_date
  end

  def oncall_exists?(user_id, start_date, end_date)
    Oncall.exists?(user_id: user_id, request_status: [0, 1], start_date: start_date..end_date, end_date: start_date..end_date)
  end

  def approved_leaves(user_id, start_date, end_date)
    Leave.where(user_id: user_id, status: 'approved')
         .where("start_date <= ? AND end_date >= ?", end_date, start_date)
  end

  def public_holidays(start_date, end_date)
    PublicHoliday.where("start_date <= ? AND end_date >= ?", end_date, start_date)
  end

  def valid_oncall_date?(date, public_holidays, approved_leaves)
    is_weekend = date.saturday? || date.sunday?
    is_public_holiday = public_holidays.any? { |holiday| date.between?(holiday.start_date, holiday.end_date) }
    is_approved_leave = approved_leaves.any? { |leave| date.between?(leave.start_date, leave.end_date) }
    is_weekend || is_public_holiday || is_approved_leave
  end
end