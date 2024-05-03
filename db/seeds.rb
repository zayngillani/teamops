# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
start_of_april = Date.new(2024, 4, 1).beginning_of_day
end_of_april = Date.new(2024, 4, -1).end_of_day
attendances_in_april = Attendance.where(user_id: 62, created_at: start_of_april..end_of_april)
attendances_in_april.destroy_all
dates_in_april = (Date.new(2024, 4, 1)..Date.new(2024, 4, -1)).to_a
working_days_in_april = dates_in_april.reject { |date| date.saturday? || date.sunday? }
min_working_hours = 7
max_working_hours = 8
working_days_in_april.each do |date|
  total_hours = min_working_hours + rand(max_working_hours - min_working_hours + 1)
  check_in_time = Time.new(date.year, date.month, date.day, 9, 0, 0)
  check_out_time = check_in_time + total_hours * 3600
  total_time_worked_seconds = check_out_time - check_in_time

  attendance = Attendance.create(
    check_in_time: check_in_time,
    check_out_time: check_out_time,
    total_hours: total_time_worked_seconds,
    created_at: check_in_time
  )

  attendance.update(user_id: 62)

end