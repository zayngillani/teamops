class Admin::OncallSupportController < ApplicationController
     def index
          @month = params[:month].present? ? params[:month].to_i : Date.today.month
          @year = params[:year].present? ? params[:year].to_i : Date.today.year
          @start_date = Date.new(@year, @month, 1)
          @end_date = @start_date.end_of_month
          current_month_start = @start_date.beginning_of_month
          current_month_end = @end_date.end_of_month
          request_status = params[:request_status].present? ? params[:request_status].to_i : nil
          @oncalls = Oncall.where("start_date <= ? AND end_date >= ?", current_month_end, current_month_start)
          @oncalls = @oncalls.where(request_status: request_status) if request_status
     end

     def show
          @oncall = Oncall.find_by(id: params[:id])  
     end

     def update
          @oncall = Oncall.find_by(id: params[:id])
          if params[:oncall].present?
               supervisor = params[:oncall][:supervisor]
          else
               supervisor = nil
          end
          if supervisor.present? && @oncall.request_status == 0
               @oncall.update!(supervisor: supervisor, request_status: 1 )
               message = "Request Approved"
          elsif @oncall.request_status == 1
               message = "Request Already Approved"
          else @oncall.request_status == 2
               message = "Request Already Rejected"
          end
          flash[:success] = message
          redirect_to admin_oncall_support_index_path(month: Date.current.month, year: Date.current.year)
     end

     def reject_request
          @oncall = Oncall.find_by(id: params[:oncall_support_id])
          if @oncall.present? && @oncall.request_status == 0
               @oncall.update!(request_status: 2)
               message = "Request Rejected"
          elsif @oncall.request_status == 1
               message = "Request Already Approved"
          else @oncall.request_status == 2
               message = "Request Already Rejected"
          end
          flash[:success] = message
          redirect_to admin_oncall_support_index_path(month: Date.current.month, year: Date.current.year)
     end
end