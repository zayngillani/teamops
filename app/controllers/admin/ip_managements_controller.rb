class Admin::IpManagementsController < ApplicationController
  require 'ipaddr'

    def index
      @ips = IpManagement.where(deleted_at: nil).order(created_at: :desc).paginate(page: params[:page], per_page: 10)
    end

    def new
      @ip_management = IpManagement.new
    end
      
    def create
      @ip = IpManagement.new
      @ip.user_name = params[:name]
      @ip.ip_address = params[:ip_address]
      exist_ip = IpManagement.where(ip_address: params[:ip_address])
      if exist_ip
        flash[:error] = "IP Address already added"
        redirect_to admin_ip_managements_path
        return
      end
      if valid_ip?(params[:ip_address])
        if @ip.save
          flash[:success] = "IP Address added successfully"
          redirect_to admin_ip_managements_path
        else
          flash[:error] = "Failed to save IP Address"
          redirect_to admin_ip_managements_path
        end
      else
        flash[:error] = "Given IP Address is not valid"
        redirect_to admin_ip_managements_path
      end
    end

    def update_status
      @ip = IpManagement.find(params[:id])
      new_status = params[:ip_management][:status]
      if @ip 
        @ip.update(status: new_status)
        render json: { success: true, status: @ip.status }
      end
    end
  
    def update
      @ip = IpManagement.find(params[:id])
      if @ip 
        @ip.update(ip_management_params)
        flash[:success] = "IP Address updated"
      else
        flash[:error] = 'IP Address not found'
      end
      redirect_to admin_ip_managements_path
    end
  
    def destroy
      @ip = IpManagement.find(params[:id])
      if @ip.soft_delete
        flash[:error] = 'IP Address removed'
      else
        flash[:alert] = 'Failed to delete the IP Address'
      end
      redirect_to admin_ip_managements_path
    end

    private

    def ip_management_params
      params.require(:ip_management).permit(:user_name, :ip_address)
    end

    def valid_ip?(ip)
      IPAddr.new(ip) rescue false
    end

end
