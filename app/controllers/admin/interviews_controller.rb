class Admin::InterviewsController < ApplicationController
  before_action :authorize_admin!

  def new 
    @job_application = JobApplication.find(params[:job_application_id])
    @interview = Interview.new
  end

  def create
    @job_application = JobApplication.find(params[:interview][:job_application_id])
    interview_scheduled = parse_datetime(params[:interview][:interview_date], params[:interview][:interview_time])
    if @job_application.interviews.count >= 1
      flash[:alert] = "Interview has been already sheduled for this candidate"
      redirect_to admin_job_application_path(@job_application)
    elsif public_holiday_on_date?(interview_scheduled.to_date)
      flash[:alert] = "Interviews cannot be scheduled on public holidays."
      redirect_to admin_job_application_path(@job_application)
    elsif interview_in_past?(interview_scheduled)
      flash[:alert] = "Cannot schedule interviews in the past. Please choose a future time."
      redirect_to admin_job_application_path(@job_application)
    else
      @interview = Interview.new(interview_params)
      if @interview.save
        flash[:success] = "Interview scheduled successfully."
        redirect_to admin_job_application_path(@interview.job_application)
      else
        flash[:error] = "#{@interview.errors.full_messages.join(', ')}"
        redirect_to new_admin_interview_path
      end
    end
  end

  def generate_public_link
    @interview = Interview.find(params[:id])
  
    existing_link = @interview.public_links.where("expires_at > ?", Time.zone.now).first
  
    if existing_link
      @public_link_url = public_link_url(existing_link.token)
    else
      @public_link = @interview.public_links.create!(expires_at: 24.hours.from_now)
      @public_link_url = public_link_url(@public_link.token)
    end
  end
  

  private

  def parse_datetime(date_str, time_str)
    time_zone = ActiveSupport::TimeZone['Asia/Karachi']
    time_zone.parse("#{date_str} #{time_str}")
  end

  def public_holiday_on_date?(date)
    PublicHoliday.on_date(date).present?
  end

  def interview_in_past?(interview_datetime)
    interview_datetime < Time.now.in_time_zone('Asia/Karachi')
  end

  def interview_params
    params.require(:interview).permit(:interview_date, :interview_time, :job_application_id)
  end

  def authorize_admin!
    redirect_to root_path, alert: 'Access Denied!' unless current_user.admin?
  end
end
