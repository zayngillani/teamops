module Api
  module V1
    class JobApplicationsController < ApplicationController
      protect_from_forgery with: :null_session
      skip_before_action :authenticate_user!, only: [:create]

      def create
        job_application = JobApplication.new(job_application_params)

        if job_application.save
          render json: { status: 'SUCCESS', message: 'Job application submitted', data: job_application }, status: :ok
        else
          render json: { status: 'ERROR', message: 'Job application not saved', data: job_application.errors }, status: :unprocessable_entity
        end
      end

      private

      def job_application_params
        params.require(:job_application).permit(:name, :email, :qualification, :cnic, :current_experience, :contact_number, :current_salary, :expected_salary, :resume_link)
      end
    end
  end
end
  