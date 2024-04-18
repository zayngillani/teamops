class HolidayController < ApplicationController
  def create
    existing_holiday = Holiday.find_by(start_date: params[:holiday][:start_date])
    if existing_holiday
      flash[:notice] = "A holiday already exists on this date."
      redirect_to holiday_index_path
    else
      @holiday = Holiday.new(holiday_params)
      if @holiday.save
        flash[:success] = "Holiday created successfully"
        redirect_to holiday_index_path
      else
        render 'new'
      end
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
