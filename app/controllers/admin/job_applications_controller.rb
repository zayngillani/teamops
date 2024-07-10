class Admin::JobApplicationsController < ApplicationController
  before_action :authorize_admin!

  def index
    @job_applications = JobApplication.all

    respond_to do |format|
      format.html
      format.json { render json: @job_applications }
    end
  end

  private
  def authorize_admin!
    redirect_to root_path, alert: 'Access Denied!' unless current_user.admin?
  end
end
