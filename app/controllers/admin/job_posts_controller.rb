
class Admin::JobPostsController < ApplicationController
  before_action :authorize_admin!
  before_action :set_job_post, only: [:show, :edit, :update, :destroy]

  def index
    @job_posts = JobPost.all.paginate(page: params[:page], per_page: 10)
  end

  def new
    @job_post = JobPost.new
  end

  def create
    @job_post = JobPost.new(job_post_params)

    if @job_post.save
      Rails.cache.delete("job_post_list")
      flash[:success] = 'Job has been Published'
      redirect_to admin_job_posts_path
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
      Rails.cache.delete("job_post_list")
      Rails.cache.delete("job_post_#{@job_post.id}")
      flash[:success] = 'Job has been updated'
      redirect_to admin_job_posts_path
    else
      error_message = @job_post.errors.full_messages.to_sentence
      flash[:error] = "#{error_message}"
      redirect_to edit_admin_job_post_path
    end
  end

  def destroy
    if @job_post.soft_delete
      Rails.cache.delete("job_post_list")
      Rails.cache.delete("job_post_#{@job_post.id}")
      flash[:error] = 'Job has been deleted'
      redirect_to admin_job_posts_path
    else
      flash[:alert] = 'Failed to delete the job'
      redirect_to admin_job_posts_path
    end

  rescue ActiveRecord::RecordNotFound
    flash[:alert] = 'Job not found'
    redirect_to admin_job_posts_path
  rescue StandardError => e
    flash[:alert] = "An error occurred: #{e.message}"
    redirect_to admin_job_posts_path
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
