class Admin::JobApplicationsController < ApplicationController
  before_action :authorize_admin!

  def index
    @job_applications = JobApplication.all
  end

  private
  def authorize_admin!
    redirect_to root_path, alert: 'Access Denied!' unless current_user.admin?
  end
end
