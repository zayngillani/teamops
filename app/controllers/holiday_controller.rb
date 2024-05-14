class HolidayController < ApplicationController
  def create
    start_date = params[:holiday][:start_date]
    end_date = params[:holiday][:end_date]
    date_start = Date.parse(params[:holiday][:start_date])
    if  params[:title].blank?
      redirect_to holiday_index_path, flash: { error: "Title can't be blank or contain only spaces" }
      return
    end
    if date_start == Date.today && Time.now.hour >= 12
      redirect_to holiday_index_path, flash: { error: "Holiday can only be added before 12 pm." }
      return
    end
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

  def destroy
    @holiday = Holiday.find_by(id: params[:id])
    if @holiday.present?
      @holiday.destroy
      flash[:success] = "Holiday deleted successfully"
      redirect_to holiday_index_path
    else
      flash[:error] = "Holiday not found"
      redirect_to holiday_index_path
    end
  end

  private

  def holiday_params
    params.require(:holiday).permit(:title, :start_date, :end_date)
  end

end
