class Admin::JobApplicationsController < ApplicationController
  
  def index
    @job_applications = JobApplication.all
  end
end
