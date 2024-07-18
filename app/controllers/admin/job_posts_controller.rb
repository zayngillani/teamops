
class Admin::JobPostsController < ApplicationController
  before_action :authorize_admin!
  before_action :set_job_post, only: [:show, :edit, :update, :destroy]

  def index
    @job_posts = JobPost.all
  end

  def new
    @job_post = JobPost.new
  end

  def create
    @job_post = JobPost.new(job_post_params)
    # Custom handling of requirememnts and qualifications
    requirements_and_qualification = params.dig(:job_post, :requirements_and_qualification)&.split('\n')
    proper_requirements_and_qualification = requirements_and_qualification[0].split("\n")
    @job_post.requirements_and_qualification = proper_requirements_and_qualification

    if @job_post.save
      redirect_to admin_job_posts_path, notice: 'Job has been Published'
    else
      redirect_to new_admin_job_post_path, error: 'There was an error saving the job post'
    end
  end

  def show
  end

  def edit
  end

  def update
  end

  def destroy
    @job_post.destroy
    redirect_to admin_job_posts_path, notice: 'Job has been deleted'
  end

  private

  def set_job_post
    @job_post = JobPost.find(params[:id])
  end

  def job_post_params
    params.require(:job_post).permit(:title, :details, :requirements_and_qualification)
  end
  

  def authorize_admin!
    redirect_to root_path, alert: 'Access Denied!' unless current_user.admin?
  end
end
