
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

    if @job_post.save
      redirect_to admin_job_posts_path, notice: 'Job has been Published'
    else
      error_message = @job_post.errors.full_messages.to_sentence
      flash[:error] = "#{error_message}"
      redirect_to new_admin_job_post_path
    end
  end

  def show
  end

  def edit
  end

  def update
    if @job_post.update(job_post_params)
      redirect_to admin_job_posts_path, notice: 'Job has been updated.'
    else
      error_message = @job_post.errors.full_messages.to_sentence
      flash[:error] = "#{error_message}"
      redirect_to new_admin_job_post_path
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
    params.require(:job_post).permit(:title, :details, :requirements_and_qualification)
  end

  def authorize_admin!
    redirect_to root_path, alert: 'Access Denied!' unless current_user.admin?
  end
end
