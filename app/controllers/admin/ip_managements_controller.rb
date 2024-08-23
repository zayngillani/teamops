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
      @ip.user_name = params[:name].strip
      @ip.ip_address = params[:ip_address]
      if IpManagement.exists?(ip_address: params[:ip_address], deleted_at: nil)
        flash[:error] = "IP Address already added"
        redirect_to admin_ip_managements_path
        return
      end
      if validate_name_and_ip(@ip.user_name, @ip.ip_address)
        if @ip.save
          flash[:success] = "IP Address added successfully"
        else
          flash[:error] = "Failed to save IP Address"
        end
      end
      redirect_to admin_ip_managements_path
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
      ip_name = params[:ip_management][:user_name]
      ip_address = params[:ip_management][:ip_address]
      if validate_name_and_ip(ip_name, ip_address)
        if @ip
          @ip.update(ip_management_params)
          flash[:success] = "IP Address updated"
        else
          flash[:error] = 'IP Address not found'
        end
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

    def validate_name_and_ip(name, ip_address)
      if name.blank?
        flash[:error] = "Name cannot be empty or contain only spaces"
        return false
      end
      unless valid_ip?(ip_address)
        flash[:error] = "Given IP Address is not valid"
        return false
      end
      true
    end

end
