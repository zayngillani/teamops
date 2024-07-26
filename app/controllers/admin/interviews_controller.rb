class Admin::InterviewsController < ApplicationController
  before_action :authorize_admin!

  def new 
    @job_application = JobApplication.find(params[:job_application_id])
    @interview = Interview.new
  end

  def create
    @job_application = JobApplication.find(params[:interview][:job_application_id])
    if @job_application.interviews.count >= 1
      flash[:alert] = "Interview has been already sheduled for this candidate"
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

  private

  def interview_params
    params.require(:interview).permit(:interview_date, :interview_time, :job_application_id)
  end

  def authorize_admin!
    redirect_to root_path, alert: 'Access Denied!' unless current_user.admin?
  end
end
