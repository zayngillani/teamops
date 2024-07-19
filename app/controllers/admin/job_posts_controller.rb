
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
      redirect_to new_admin_job_post_path, error: 'There was an error saving the Job'
    end
  end

  def show
    @requirements = @job_post.requirements_and_qualification.map do |req|
      req.strip.gsub(/^[\s\u00a0]+|[\s\u00a0]+$/, '').gsub("\n", "")
    end
  end

  def edit
    @job_post.requirements_and_qualification = @job_post.requirements_and_qualification.map do |req|
      req.strip.gsub(/^[\s\u00a0]+|[\s\u00a0]+$/, '').gsub("\n", "")
    end
  end

  def update
    @job_post.title = params.dig(:job_post, :title)
    @job_post.details = params.dig(:job_post, :details)
    @job_post.requirements_and_qualification = JSON.parse(params.dig(:job_post, :requirements_and_qualification))
    
    if @job_post.save!
      redirect_to admin_job_posts_path, notice: 'Job has been updated.'
    else
      redirect_to edit_admin_job_post_path, error: 'There was an error editinf the Job'
    end
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
    params.require(:job_post).permit(:title, :details)
  end

  def authorize_admin!
    redirect_to root_path, alert: 'Access Denied!' unless current_user.admin?
  end
end
