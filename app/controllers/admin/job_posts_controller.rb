
class Admin::JobPostsController < ApplicationController
  before_action :authorize_admin!
  before_action :set_job_post, only: [:show, :edit, :update, :destroy]

  def index
    @job_posts = JobPost.all
    @job_post = JobPost.new
  end

  def create
    @job_post = JobPost.new(job_post_params)

    respond_to do |format|
      if @job_post.save
        format.html { redirect_to admin_job_posts_path, notice: 'Job post was successfully created.' }
        format.js   # This will render create.js.erb
      else
        format.html { render :new }
        format.js   # This will render create.js.erb
      end
    end
  end

  def show
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
