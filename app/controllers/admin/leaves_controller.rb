class Admin::LeavesController < ApplicationController
     def index
          @month = params[:month].present? ? params[:month].to_i : Date.today.month
          @year = params[:year].present? ? params[:year].to_i : Date.today.year
          @start_date = Date.new(@year, @month, 1)
          @end_date = @start_date.end_of_month
          current_month_start = @start_date.beginning_of_month
          current_month_end = @end_date.end_of_month
          status = params[:status].present? ? params[:status].to_i : nil
          @leaves = Leave.where("start_date <= ? AND end_date >= ?", current_month_end, current_month_start)
          if status
            @leaves = @leaves.where(status: status)
          end
          @leaves = @leaves.order(created_at: :desc).paginate(page: params[:page], per_page: 10)
     end

     def show
          @leave = Leave.find_by(id: params[:id])
          @user = User.find_by(id: @leave.user_id)
          @leave_days_count = (@leave.end_date - @leave.start_date).to_i + 1
     end

     def update
          @leave = Leave.find_by(id: params[:id])
          if params[:leave][:action_type] == "approve"
               if params[:leave].present?
                    supervisor = params[:leave][:supervisor]
               else
                    supervisor = nil
               end
               if supervisor.present? && @leave.status == "pending"
                    @leave.update!(supervisor: supervisor, status: 1 )
                    SlackService.new(current_user, "Leave approved by", @leave).send_leave
                    message = "Leave Approved"
               else
                    message = "Leave not found"
               end
          else
               if @leave.present? && @leave.status == "pending"
                    @leave.update!(status: 2, supervisor: params[:leave][:supervisor].present? ? params[:leave][:supervisor] : nil)
                    error = "Leave Rejected"
               else @oncall.request_status == 2
                    message = "Leave not found"
               end
          end
               if message
                    flash[:success] = message
               else
                    flash[:error] = error
               end
               redirect_to admin_leaves_path
     end
end