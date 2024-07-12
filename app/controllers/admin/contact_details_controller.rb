class Admin::ContactDetailsController < ApplicationController
  before_action :authorize_admin!

  def index
    @contact_details = ContactDetail.all

    respond_to do |format|
      format.html
      format.json { render json: @contact_details }
    end
  end

  private
  
  def authorize_admin!
    redirect_to root_path, alert: 'Access Denied!' unless current_user.admin?
  end
end
