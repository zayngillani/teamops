class HolidayController < ApplicationController
  def create
    binding.pry
    @holiday = Holiday.new
    @holiday.title = params[:holiday][:title]
    @holiday.start_date = params[:holiday][:start_date]
    @holiday.end_date = params[:holiday][:end_date]
    @users = User.all
    @attendances = {}

    if @holiday.save!
      @users.each do |user|
        attendance_entries = []
          @holiday.start_date..@holiday.end_date.each do |date|
            binding.pry
            attendance = Attendance.find_or_initialize_by(user_id: user.id, date: date)
            attendance_entries << attendance
          end
          @attendances[user.id] = attendance_entries
        end
      @attendance = Attendance.new()
      flash[:success]  = "Holiday created successfully"
      redirect_to root_path
    else
      render 'new'
    end
  end

  def new
    @holiday = Holiday.new
  end
end
