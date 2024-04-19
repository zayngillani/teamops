class HolidayController < ApplicationController
  def create
    start_date = params[:holiday][:start_date]
    end_date = params[:holiday][:end_date]
    if start_date > end_date
      redirect_to holiday_index_path, flash: { error: "End date must be greater than or equal to start date" }
      return
    end
    existing_holiday = Holiday.find_by(start_date: start_date)
    if existing_holiday
      redirect_to holiday_index_path, flash: { error: "A holiday already exists on this date." }
      return
    end
    @holiday = Holiday.new(holiday_params)
    if @holiday.save
      flash[:success] = "Holiday created successfully"
      redirect_to holiday_index_path
    else
      render 'new'
    end
  end

  def new
    @holiday = Holiday.new
  end

  def index
    @holidays = Holiday.all
  end

  private

  def holiday_params
    params.require(:holiday).permit(:title, :start_date, :end_date)
  end

end
