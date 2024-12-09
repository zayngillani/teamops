class Admin::ContactDetailsController < ApplicationController
  before_action :authorize_admin!

  def index
    @contact_details = ContactDetail.all

    if params[:q].present?
      search_query = params[:q]
      @contact_details = ContactDetail.search_by_contact_type(search_query)
    end

    @contact_details = @contact_details.paginate(page: params[:page], per_page: 10)

    respond_to do |format|
      format.html 
      format.js do
        render partial: 'admin/contact_details/contact_detail', collection: @contact_details, as: :contact_detail
      end
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
