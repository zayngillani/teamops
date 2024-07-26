class PublicLinksController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]
  layout false, only: [:show]

  def show
    @public_link = PublicLink.find_by!(token: params[:token])

    if @public_link.present?
      @interview = @public_link.interview
      @job_application = @interview.job_application
      @job_post = @job_application.job_post
    end
  end
end
