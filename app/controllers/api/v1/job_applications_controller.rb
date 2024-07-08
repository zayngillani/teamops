# app/controllers/api/v1/job_applications_controller.rb
require 'net/ftp'

module Api
  module V1
    class JobApplicationsController < ApplicationController
      protect_from_forgery with: :null_session
      skip_before_action :authenticate_user!, only: [:create]

      def create
        @job_application = JobApplication.new(job_application_params)

        if params[:resume].present?
          if @job_application.save
            # Call the Slack notification service
            JobApplicationSlackService.new(@job_application, params[:job_title], params[:resume]).notify_submission
            # Upload resume to FTP
            upload_to_ftp(params[:resume])

            render json: { status: 'SUCCESS', message: 'Job application submitted', data: @job_application }, status: :ok
          else
            render json: { status: 'ERROR', message: 'Job application not saved', data: @job_application.errors }, status: :unprocessable_entity
          end
        else
          render json: { status: 'ERROR', message: 'Resume file not provided' }, status: :unprocessable_entity
        end
      end

      private

      def job_application_params
        params.require(:job_application).permit(:name, :email, :qualification, :cnic, :current_experience, :contact_number, :current_salary, :expected_salary)
      end

      def upload_to_ftp(file)
        begin
          ftp = Net::FTP.new
          ftp.connect(ENV['FTP_HOST'], ENV['FTP_PORT'].to_i)
          ftp.login(ENV['FTP_USERNAME'], ENV['FTP_PASSWORD'])
          ftp.passive = true
        
          # Extract the original filename from the file object
          original_filename = file.original_filename
          remote_filename = original_filename
        
          ftp.putbinaryfile(file.path, remote_filename)
        
          ftp.close
          @job_application.update(resume_link: remote_filename)
        
          Rails.logger.info "Uploaded #{remote_filename} to FTP server"
        rescue StandardError => e
          Rails.logger.error "FTP upload failed: #{e.message}"
          raise "FTP upload failed: #{e.message}"
        end
      end
    end
  end
end
