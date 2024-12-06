class Admin::ContactDetailsController < ApplicationController
  before_action :authorize_admin!

  def index
    @contact_details = ContactDetail.all

    if params[:q].present?
      search_query = params[:q]
      @contact_details = ContactDetail.search_by_contact_type(search_query)
    end

    respond_to do |format|
      format.html
      format.js { render json: @contact_details }
    end
  end

  def show
    @contact_detail = ContactDetail.find(params[:id])
  end

  private
  
  def authorize_admin!
    redirect_to root_path, alert: 'Access Denied!' unless current_user.admin?
  end
end
