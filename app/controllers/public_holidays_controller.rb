class PublicHolidaysController < ApplicationController
  def create
    start_date = Date.parse(params[:public_holiday][:start_date])
    end_date = Date.parse(params[:public_holiday][:end_date])
    if (start_date..end_date).any? { |date| date.saturday? || date.sunday? }
      redirect_to public_holidays_path, flash: { error: "Holidays cannot start or end on a weekend." }
      return
    elsif start_date == Date.today && Time.now.hour >= 12
      redirect_to public_holidays_path, flash: { error: "Holiday can only be added before 12 pm." }
      return
    elsif start_date > end_date
      redirect_to public_holidays_path, flash: { error: "End date must be greater than or equal to start date" }
      return
    end
    existing_holiday = PublicHoliday.where("start_date <= ? AND end_date >= ?", end_date, start_date).exists? ||
    PublicHoliday.where(start_date: start_date..end_date).exists?
    if existing_holiday
      redirect_to public_holidays_path, flash: { error: "A holiday already exists within the specified date range." }
      return
    end
    
    @holiday = PublicHoliday.new(holiday_params)
    if @holiday.save
      flash[:success] = "Holiday Created"
      redirect_to public_holidays_path
    else
      render 'new'
    end
  end
  
  def new
    @holiday = PublicHoliday.new
  end

  def index
    @holidays = PublicHoliday.all
  end

  def destroy
    @holiday = PublicHoliday.find_by(id: params[:id])
    if @holiday.present?
      @holiday.destroy
      flash[:success] = "Holiday deleted successfully"
      redirect_to public_holidays_path
    else
      flash[:error] = "Holiday not found"
      redirect_to public_holidays_path
    end
  end

  private

  def holiday_params
    params.require(:public_holiday).permit(:title, :start_date, :end_date)
  end

end
