class HolidayController < ApplicationController
  def create
    @holiday = Holiday.new
    @holiday.title = params[:holiday][:title]
    @holiday.start_date = params[:holiday][:start_date]
    @holiday.end_date = params[:holiday][:end_date]
    @holiday.save!
    if @holiday.present?
      flash[:success]  = "Holiday created successfully"
      redirect_to root_path
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
end
