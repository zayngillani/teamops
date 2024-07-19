class Admin::JobApplicationsController < ApplicationController
  before_action :authorize_admin!

  def index
    @job_post = JobPost.find (params[:job_post_id])
    @job_applications = @job_post.job_applications.available.all

    respond_to do |format|
      format.html
      format.json { render json: @job_applications }
    end
  end

  def show
    @job_application = JobApplication.find (params[:id])
  end

  def reject_applicant
    @job_application = JobApplication.find (params[:id])

    if @job_application.update(is_rejected: true)
      flash[:notice] = "Job application rejected successfully."
    else
      flash[:alert] = "Failed to update job application."
    end
  
    redirect_to admin_job_applications_path
  end

  private
  def authorize_admin!
    redirect_to root_path, alert: 'Access Denied!' unless current_user.admin?
  end
end
