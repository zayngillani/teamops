class Admin::JobApplicationsController < ApplicationController
  before_action :authorize_admin!

  def index
    @job_post = JobPost.find (params[:job_post_id])
    @job_applications = @job_post.job_applications.available.all.paginate(page: params[:page], per_page: 10)

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
    if @job_application.update(interview_status: 3)
       @job_post = JobPost.find_by(id: @job_application.job_post.id)
      # send_reject_email(@job_application, @job_post)
      flash[:alert] = "Candidate Rejected"
    else
      flash[:error] = "Failed to Rejected the candidate."
    end
  
    redirect_to admin_job_applications_path(job_post_id: @job_application.job_post.id)
  end

  def download_resume
    @job_application = JobApplication.find(params[:id])
    resume_link = @job_application.resume_link

    if resume_link.present?
      begin
        file_path = fetch_resume_from_ftp(resume_link)
        send_file(file_path, filename: File.basename(file_path), type: 'application/pdf', disposition: 'inline')
      rescue StandardError => e
        Rails.logger.error "FTP download failed: #{e.message}"
        flash[:error] = "FTP download failed: #{e.message}"
        redirect_to admin_job_application_path(@job_application)
      end
    else
      flash[:error] = 'Resume not found.'
      redirect_to admin_job_application_path(@job_application)
    end
  end

  private

  def authorize_admin!
    redirect_to root_path, alert: 'Access Denied!' unless current_user.admin?
  end

  def fetch_resume_from_ftp(resume_link)
    ftp = Net::FTP.new
    ftp.connect(ENV['FTP_HOST'], ENV['FTP_PORT'].to_i)
    ftp.login(ENV['FTP_USERNAME'], ENV['FTP_PASSWORD'])
    ftp.passive = true

    local_file_path = Rails.root.join('tmp', File.basename(resume_link))

    File.open(local_file_path, 'wb') do |file|
      ftp.getbinaryfile(resume_link, file.path)
    end

    ftp.close

    local_file_path
  rescue StandardError => e
    Rails.logger.error "FTP download failed: #{e.message}"
    raise "FTP download failed: #{e.message}"
  end

  def send_reject_email(job_application, job_post)
    JobApplicationMailer.rejection_email(job_application, job_post).deliver_now
  end
end
